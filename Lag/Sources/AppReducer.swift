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
import SpeedTestKit
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

extension Speed: Equatable {
    public static func == (lhs: Speed, rhs: Speed) -> Bool {
        lhs.units == rhs.units
            && lhs.value == rhs.value
    }
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
    
    case presentScanner
    case forceDismissScanner
    case dismissScanner
    case startScannerDownload
    case startScannerUpload
    case startSaveResults
    case saveCompleted
    case updateDownloadScanner(Speed, Speed)
    case updateUploadScanner(Speed, Speed)
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
    let downloadService = CustomHostDownloadService()
    let uploadService = CustomHostUploadService()
    let geocoder = CLGeocoder()
    let nwPathMonitor = NWPathMonitor()
}

struct LocationManagerId: Hashable {}

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
        
    case .startScannerDownload:
        state.scanning = .started
        return Effect.run { subscriber in
            environment.downloadService.test(URL(string: "http://test.byfly.by/speedtest/upload.php")!,
                                             fileSize: 10000000,
                                             timeout: 30,
                                             current: { (current, average) in
                                                subscriber.send(.updateDownloadScanner(current, average))
                                             }, final: { result in
                                                subscriber.send(.startScannerUpload)
                                             })
            return AnyCancellable {}
        }
        
        
    case let .updateDownloadScanner(current, average):
        state.scanResult.download = average.description
        state.scanResult.downloadRaw = average.value
        state.scanResult.downloadUnits = average.units.rawValue
        break
        
    case .startScannerUpload:
        return Effect.run { subscriber in
            environment.uploadService.test(URL(string: "http://test.byfly.by/speedtest/upload.php")!,
                                           fileSize: 10000000,
                                           timeout: 30,
                                           current: { (current, average) in
                                            subscriber.send(.updateUploadScanner(current, average))
                                           }, final: { result in
                                            subscriber.send(.startSaveResults)
                                           })
            return AnyCancellable {}
        }
        
    case let .updateUploadScanner(current, average):
        state.scanResult.upload = average.description
        state.scanResult.uploadRaw = average.value
        state.scanResult.uploadUnits = average.units.rawValue
        break
        
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
