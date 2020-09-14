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
import MapKit

struct GeoLoc: Codable, Equatable {
    var lat: Double
    var lng: Double
}

struct ScanResult: Codable, Equatable {
    var objectID: ObjectID
    var address: String? = nil
    var _geoloc: GeoLoc? = nil
    var download: String? = nil
    var downloadRaw: Double = 0.0
    var downloadUnits: Int = 0
    var upload: String? = nil
    var uploadRaw: Double = 0.0
    var uploadUnits: Int = 0
    var onWiFi: Bool = false
    var pointOfInterest: String?
    var pointOfInterestDescription: String?
}

struct Latency: Codable {
    var address: String
    var speedBits: UInt
}

struct SearchResult: Equatable, Hashable {
    var pointOfInterest: String?
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
    var showScanner: Bool = false
    var isEditing: Bool = false
    var scanning: ScanningState = .notStarted
    var queryString: String = ""
    var queryResults = [SearchResult]()
    var scanResult = ScanResult(objectID: ObjectID(stringLiteral: UUID().uuidString))
    var isUnscannedLocation = true
    var establishmentPickerIndex = 0
    var previousLocation: CLLocation? = nil
}


enum AppAction: Equatable {
    case locationManager(LocationManager.Action)
    case fastManager(FastManager.Action)
    
    case presentScanner
    case dismissScanner
    case startSaveResults
    case saveCompleted
    case startTest
    case setIsEditing(Bool)
    case updateQuery(String)
    case updateResults([SearchResult])
    case updateOnWiFi(Bool)
    case updateNearestPointOfInterest(String?, String?)
    case reverseGeocode(CLLocation?)
    case clearQuery
    case setEstablishment(Int)

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
        state.scanning = .notStarted
        state.scanResult.download = nil
        state.scanResult.downloadRaw = 0.0
        state.scanResult.downloadUnits = 0
        state.scanResult.upload = nil
        state.scanResult.uploadRaw = 0.0
        state.scanResult.uploadUnits = 0
        state.showScanner = true
        return .none
        
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
                        
                        return SearchResult(pointOfInterest: hit.object["pointOfInterest"]?.object() as? String,
                                            address: address,
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
        return .none
        
    case let .updateResults(results):
        state.queryResults = results
        return .none
        
    case .clearQuery:
        state.isEditing = false
        state.queryString = ""
        state.queryResults = [SearchResult]()
        return .none
        
    case .startTest:
        state.scanning = .started
        return environment.fastManager.startTest(id: FastManagerId()).fireAndForget()
        
    case let .updateOnWiFi(onWiFi):
        state.scanResult.onWiFi = onWiFi
        return .none
        
    case .startSaveResults:
        guard let data = state.scanResult.address?.data(using: .utf8) else { return .none }
        let digest = Insecure.SHA1.hash(data: data)
        
        switch UserDefaults.standard.array(forKey: Constants.scannedLocationsKey) as? [String] {
        case var .some(scannedLocations):
            scannedLocations.append(digest.hexStr)
            UserDefaults.standard.setValue(scannedLocations, forKey: Constants.scannedLocationsKey)
        case .none:
            UserDefaults.standard.setValue([digest.hexStr], forKey: Constants.scannedLocationsKey)
        }

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
        return .none
        
    case let .setEstablishment(index):
        state.establishmentPickerIndex = index
        
        guard let category = Constants.pointsOfInterest[index].category,
              let coordinate = state.scanResult._geoloc else {
            return Effect(value: .reverseGeocode(state.previousLocation)) }
        
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = Constants.pointsOfInterest[index].name
        searchRequest.pointOfInterestFilter = MKPointOfInterestFilter(including: [category])
        searchRequest.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: coordinate.lat,
                                                                                 longitude: coordinate.lng),
                                           latitudinalMeters: 50,
                                           longitudinalMeters: 50)

        let myLocation = CLLocation(latitude: coordinate.lat, longitude: coordinate.lng)
        
        return .future { completion in
            let search = MKLocalSearch(request: searchRequest)
            search.start { (response, error) in
                guard let items = response?.mapItems.filter({ $0.name != nil && $0.placemark.location != nil }) else { return }
                var currentDistance: Double = Double.greatestFiniteMagnitude
                var closestItem: MKMapItem?
                
                for item in items {
                    guard let location = item.placemark.location else { continue }
                    let itemDistance = myLocation.distance(from: location)
                    if itemDistance < currentDistance {
                        closestItem = item
                        currentDistance = itemDistance
                    }
                }
                
                guard let poiName = closestItem?.name,
                      let address = closestItem?.placemark.address else { return }
                completion(.success(.updateNearestPointOfInterest(poiName, address)))
            }
        }
        
    case let .updateNearestPointOfInterest(poi, address):
        guard state.scanning == .notStarted else { return .none }
        
        state.scanResult.pointOfInterest = poi
        state.scanResult.pointOfInterestDescription = state.establishmentPickerIndex == 0 ? nil : Constants.pointsOfInterest[state.establishmentPickerIndex].name
        state.scanResult.address = address
        
        guard let data = state.scanResult.address?.data(using: .utf8) else { return .none }
        let digest = Insecure.SHA1.hash(data: data)
        
        guard let scannedLocation = UserDefaults.standard
                        .array(forKey: Constants.scannedLocationsKey)?
                        .compactMap({ $0 as? String})
                        .contains(digest.hexStr),
              state.isUnscannedLocation else { return .none }
  
        if !scannedLocation {
            state.showScanner = true
        }
        
        state.isUnscannedLocation = false
        return .none
        
    case .dismissScanner:
        state.showScanner = false
        return .none
        
    case let .locationManager(action):
        switch action {
        case let .didUpdateLocations(locations):
            guard let location = locations.last?.rawValue else {  return .none }
            
            state.previousLocation = location
            state.scanResult._geoloc = GeoLoc(lat: location.coordinate.latitude,
                                              lng: location.coordinate.longitude)
            return Effect(value: .reverseGeocode(location))
        default:
            return .none
        }
        
    case let .reverseGeocode(location):
        switch location {
        case let .some(location):
            return .future { completion in
                environment.geocoder
                    .reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in
                        guard error == nil,
                              let address = placemarks?.first?.address else { return }
                        completion(.success(.updateNearestPointOfInterest(nil, address)))
                    })
            }
        case .none:
            return .none
        }

        
    case let .fastManager(action):
        switch action {
        case let .didReceive(message: message):
            guard let body = message.body as? NSDictionary,
                  let type = body["type"] as? String,
                  let units = body["units"] as? String,
                  let value = body["value"] as? String else {  return .none }
            
            switch type {
            case "down":
                state.scanResult.download = "\(value) \(units)"
                state.scanResult.downloadRaw = Double(value) ?? 0.0
                state.scanResult.downloadUnits = Units(rawValue: units)?.integer ?? -1
                return .none

            case "down-done":
                return .none
                
            case "up":
                state.scanResult.upload = "\(value) \(units)"
                state.scanResult.uploadRaw = Double(value) ?? 0.0
                state.scanResult.uploadUnits = Units(rawValue: units)?.integer ?? -1
                return .none

            case "up-done":
                return Effect(value: .startSaveResults)
            default:
                return .none
            }
        }
        
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
        state.isUnscannedLocation = true
        return .none
        
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
                         distanceFilter: 20,
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
})

extension CLPlacemark {
    var address: String? {
        guard let postalAddress = self.postalAddress else { return nil }
        let postalAddressFormatter = CNPostalAddressFormatter()
        postalAddressFormatter.style = .mailingAddress
        return postalAddressFormatter.string(from: postalAddress)
    }
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
