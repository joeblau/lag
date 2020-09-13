//
//  AppReducer.swift
//  Latency
//
//  Created by Joe Blau on 9/11/20.
//

import Foundation
import Combine
import ComposableArchitecture
import ComposableCoreLocation
import AlgoliaSearchClient
import Contacts
import CryptoKit
import SystemConfiguration.CaptiveNetwork
import Network
import UIKit

struct GeoLoc: Codable, Equatable {
    var lat: Double
    var lng: Double
}

struct ScanResult: Codable, Equatable {
    var objectID: ObjectID
    var address: String = ""
    var _geoloc: GeoLoc = GeoLoc(lat: 0, lng: 0)
    var download: String = "-"
    var downloadRaw: Double = 0.0
    var downloadUnits: Int = 0
    var upload: String = "-"
    var uploadRaw: Double = 0.0
    var uploadUnits: Int = 0
    var onWiFi: Bool = false
    var service: String?
}

struct Latency: Codable {
    var address: String
    var speedBits: UInt
}

struct SearchResult: Equatable, Hashable {
    var address: String = "-"
    var download: String = "-"
    var upload: String = "-"
}

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        fabs(lhs.latitude - rhs.latitude) < Double.ulpOfOne &&
            fabs(lhs.longitude - lhs.longitude) < Double.ulpOfOne
    }
}

extension Digest {
    var bytes: [UInt8] { Array(makeIterator()) }
    var data: Data { Data(bytes) }

    var hexStr: String {
        bytes.map { String(format: "%02X", $0) }.joined()
    }
}

enum ScanningState: Equatable {
    case notStarted
    case started
    case completed
    case saved
}

struct AppState: Equatable {
    var showScanner: Bool = true
    var isEditing: Bool = false
    var scanning: ScanningState = .notStarted
    var queryString: String = ""
    var queryResults = [SearchResult]()
    var scanResult = ScanResult(objectID: ObjectID(stringLiteral: UUID().uuidString))
}


enum AppAction: Equatable {
    case locationManager(LocationManager.Action)
    case fastManager(FastManager.Action)

    case presentScanner
    case forceDismissScanner
    case dismissScanner
    case startSaveResults
    case saveCompleted
    case startTest
    case setIsEditing(Bool)
    case updateQuery(String)
    case updateResults([SearchResult])
    case updateAddress(String)
    case updateOnWiFi(Bool)
    case clearQuery
    
    case scanViewAppeared
    
    // Lifecycle
    case onActive
    case onInactive
    case onBackground
    
    // Location Manager
    case startLocationManager
    case stopLocationManager
}

struct AppEnvironment {
    let latencyIndex: Index
    let locationManager: LocationManager
    let fastManager: FastManager
    let geocoder = CLGeocoder()
    let nwPathMonitor = NWPathMonitor()
}

struct LocationManagerId: Hashable {}
struct FastManagerId: Hashable {}

let app = Reducer<AppState, AppAction, AppEnvironment>({ state, action, environment in
    switch action {
    case .presentScanner:
        state.showScanner = true
        
    case let .updateQuery(query):
        state.queryString = query
        
        return .future { completion in
            environment.latencyIndex.search(query: Query(query)) { result in
                switch result {
                case let .success(response):
                    let results = response.hits.compactMap { hit -> SearchResult? in
                        guard let address = hit.object["address"]?.object() as? String,
                              let download = hit.object["download"]?.object() as? String,
                              let upload = hit.object["upload"]?.object() as? String else { return nil }
                        return SearchResult(address: address,
                                     download: download,
                                     upload: upload)
                    }
                    
                    completion(.success(.updateResults(results)))
                case let .failure(error):
                    logger.error("\(error.localizedDescription)")
                }
            }
        }
        
    case let .setIsEditing(isEditing):
        state.isEditing = isEditing
        
    case let .updateResults(results):
        state.queryResults = results
            
    case .clearQuery:
        state.isEditing = false
        state.queryString = ""
        state.queryResults = [SearchResult]()
        
    case .startTest:
        state.scanning = .started
        return environment.fastManager.startTest(id: FastManagerId()).fireAndForget()
        
    case let .updateOnWiFi(onWiFi):
        state.scanResult.onWiFi = onWiFi
        
    case .startSaveResults:
        guard let data = state.scanResult.address.data(using: .utf8) else { return .none }
        let digest = Insecure.SHA1.hash(data: data)

        state.scanning = .completed
        state.scanResult.objectID = ObjectID(stringLiteral: digest.hexStr)
        let scanResults = [state.scanResult]
        
        return .future { completion in
            environment.latencyIndex.saveObjects(scanResults, autoGeneratingObjectID: true) { result in
                switch result {
                case let .success(response):
                    completion(.success(.saveCompleted))
                case let .failure(error):
                    logger.error("\(error.localizedDescription)")
                }
            }
        }
        
    case .saveCompleted:
        state.scanning = .saved
        break
        
    case let .updateAddress(address):
        state.scanResult.address = address
        break

    case .forceDismissScanner:
        state.showScanner = false
        return Effect(value: AppAction.dismissScanner)
        
    case .dismissScanner:
        state.scanning = .notStarted
        break
        
    case let .locationManager(action):
        switch action {
        case let .didUpdateLocations(locations):
            guard let location = locations.last?.rawValue else { break }
            
            state.scanResult._geoloc = GeoLoc(lat: location.coordinate.latitude,
                                              lng: location.coordinate.longitude)
            
            return .future { completion in
                environment.geocoder
                    .reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in
                        guard error == nil,
                              let postalAddress = placemarks?.first?.postalAddress else { return }
                        
                        let postalAddressFormatter = CNPostalAddressFormatter()
                        postalAddressFormatter.style = .mailingAddress
                        let address = postalAddressFormatter.string(from: postalAddress)
                        
                        completion(.success(.updateAddress(address)))
                    })
            }
            
        default: break
        }
    
    case let .fastManager(action):
        switch action {
        case let .didReceive(message: message):
            guard let body = message.body as? NSDictionary,
                  let type = body["type"] as? String,
                  let units = body["units"] as? String,
                  let value = body["value"] as? String else { break }

            
            switch type {
            case "down":
                state.scanResult.download = "\(value) \(units)"
                state.scanResult.downloadRaw = Double(value) ?? 0.0
                state.scanResult.downloadUnits = Units(rawValue: units)?.integer ?? -1
            case "down-done":
                print("lock it")
                
            case "up":
                state.scanResult.upload = "\(value) \(units)"
                state.scanResult.uploadRaw = Double(value) ?? 0.0
                state.scanResult.uploadUnits = Units(rawValue: units)?.integer ?? -1
            case "up-done":
                return Effect(value: .startSaveResults)
            default: break
            }
            
        }
        break
        
    case .scanViewAppeared:
//        if let clipboard = UIPasteboard.general.string,
//           let url = URL(string: clipboard) {
//            print(url.host)
//        }
        break
        
    // MARK: - Lifecycle
    
    case .onActive:
        return .merge(
            environment.locationManager.create(id: LocationManagerId()).map(AppAction.locationManager),
            environment.fastManager.create(id: FastManagerId()).map(AppAction.fastManager),
            Effect(value: AppAction.startLocationManager),
            Effect.run { subscriber in
                environment.nwPathMonitor.start(queue: .main)
                environment.nwPathMonitor.pathUpdateHandler = { path in
                    let onWifi = path.usesInterfaceType(.wifi)
                    subscriber.send(.updateOnWiFi(onWifi))
                }
                return AnyCancellable {}
            }
        )
    case .onInactive:
        break
        
    case .onBackground:
        return .merge(
            Effect(value: AppAction.stopLocationManager),
            environment.fastManager.destroy(id: FastManagerId()).fireAndForget(),
            environment.locationManager.destroy(id: LocationManagerId()).fireAndForget()
        )
        
    // MARK: - Location Manager
    
    case .startLocationManager:
        switch environment.locationManager.authorizationStatus() {
        case .notDetermined:
            return environment.locationManager
                .requestWhenInUseAuthorization(id: LocationManagerId())
                .fireAndForget()
            
        case .authorizedAlways, .authorizedWhenInUse:
            return .merge(
                environment.locationManager
                    .set(id: LocationManagerId(),
                         activityType: .none,
                         allowsBackgroundLocationUpdates: false,
                         desiredAccuracy: kCLLocationAccuracyBest,
                         distanceFilter: nil,
                         headingFilter: 8,
                         headingOrientation: .faceUp,
                         pausesLocationUpdatesAutomatically: true,
                         showsBackgroundLocationIndicator: true)
                    .fireAndForget(),
                environment.locationManager
                    .startUpdatingLocation(id: LocationManagerId())
                    .fireAndForget()
            )
        case .restricted:
            return .none
        case .denied:
            return .none
        @unknown default:
            return .none
        }
        
    case .stopLocationManager:
        return environment.locationManager
            .stopUpdatingLocation(id: LocationManagerId())
            .fireAndForget()
    }
    
    return .none
})
.combined(with: locationManager.pullback(state: \.self,
                                         action: /AppAction.locationManager,
                                         environment: { $0 }))
.combined(with: fastManager.pullback(state: \.self,
                                         action: /AppAction.fastManager,
                                         environment: { $0 }))

let locationManager = Reducer<AppState, LocationManager.Action, AppEnvironment> { _, _, _ in
    return .none
}

let fastManager = Reducer<AppState, FastManager.Action, AppEnvironment> { state, action, _ in
    return .none
}


enum Units: String {
    case Kbps
    case Mbps
    case Gbps
    
    var integer: Int {
        switch self {
        case .Kbps: return 0
        case .Mbps: return 1
        case .Gbps: return 2
        }
    }
}
