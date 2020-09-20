// AppReducer.swift
// Copyright (c) 2020 Submap

import AlgoliaSearchClient
import Combine
import ComposableArchitecture
import ComposableCoreLocation
import ComposableFast
import CryptoKit
import MapKit
import Network
import SystemConfiguration.CaptiveNetwork
import UIKit

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

struct GeoLoc: Codable, Equatable {
    var lat: Double
    var lng: Double
}

struct AppState: Equatable {
    var searchState = SearchState()

    var isUnscannedLocation = true
    var previousLocation: CLLocation? = nil
}

// MARK: - Composable

enum AppAction: Equatable {
    case updateOnWiFi(Bool)
    case updateNearestPointOfInterest(String?, String?)
    case reverseGeocode(CLLocation?)
    case setEstablishment(Int)

    // Delegates
    case searchManager(SearchAction)
    case locationManager(LocationManager.Action)

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

let app = Reducer<AppState, AppAction, AppEnvironment>({ state, action, environment in
    switch action {
    case let .updateOnWiFi(onWiFi):
        state.searchState.scanState.scanResult.onWiFi = onWiFi
        return .none

    case let .updateNearestPointOfInterest(poi, address):
        guard state.searchState.scanState.scanning == .notStarted else { return .none }

        state.searchState.scanState.scanResult.pointOfInterest = poi
        state.searchState.scanState.scanResult.pointOfInterestDescription = state.searchState.scanState.establishmentPickerIndex == 0 ? nil : Constants.pointsOfInterest[state.searchState.scanState.establishmentPickerIndex].name
        state.searchState.scanState.scanResult.address = address

        guard let data = state.searchState.scanState.scanResult.address?.data(using: .utf8) else { return .none }
        let digest = Insecure.SHA1.hash(data: data)

        guard let scannedLocation = UserDefaults.standard
            .array(forKey: Constants.scannedLocationsKey)?
            .compactMap({ $0 as? String })
            .contains(digest.hexStr),
            state.isUnscannedLocation else { return .none }

        if !scannedLocation {
            state.searchState.showScanner = true
        }

        state.isUnscannedLocation = false
        return .none

    case let .reverseGeocode(location):
        switch location {
        case let .some(location):
            return .future { completion in
                environment.geocoder
                    .reverseGeocodeLocation(location, completionHandler: { placemarks, error in
                        guard error == nil,
                            let address = placemarks?.first?.address else { return }
                        completion(.success(.updateNearestPointOfInterest(nil, address)))
                    })
            }
        case .none:
            return .none
        }

    // MARK: - Manager Delegates

    case let .searchManager(.scanManager(.setEstablishment(index))):
        state.searchState.scanState.establishmentPickerIndex = index

        guard let category = Constants.pointsOfInterest[index].category,
            let coordinate = state.searchState.scanState.scanResult._geoloc
        else {
            return Effect(value: .reverseGeocode(state.previousLocation))
        }

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
            search.start { response, _ in
                guard let items = response?.mapItems.filter({ $0.name != nil && $0.placemark.location != nil }) else { return }
                var currentDistance = Double.greatestFiniteMagnitude
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

    case let .locationManager(action):
        switch action {
        case let .didUpdateLocations(locations):
            guard let location = locations.last?.rawValue else { return .none }

            state.previousLocation = location
            state.searchState.scanState.location = location
            state.searchState.scanState.scanResult._geoloc = GeoLoc(lat: location.coordinate.latitude,
                                                                    lng: location.coordinate.longitude)
            return Effect(value: .reverseGeocode(location))
        default:
            return .none
        }

    // MARK: - Lifecycle

    case .onActive:
        print(CLLocation(latitude: 200.0, longitude: 200.0).coordinate)
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
        state.isUnscannedLocation = true
        return .none

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

    default:
        return .none
    }
})
    .combined(with: searchReducer.pullback(state: \.searchState,
                                           action: /AppAction.searchManager,
                                           environment: { $0 }))
