// ScanReducer.swift
// Copyright (c) 2020 Submap

import AlgoliaSearchClient
import ComposableArchitecture
import CryptoKit
import Foundation

enum ScanningState: Equatable {
    case notStarted
    case started
    case completed
    case saved
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

// MARK: - Composable

struct ScanState: Equatable {
    var establishmentPickerIndex = 0
    var scanning: ScanningState = .notStarted
    var scanResult = ScanResult(objectID: ObjectID(stringLiteral: UUID().uuidString))
}

enum ScanAction: Equatable {
    case dismissScanner

    case startSaveResults
    case saveCompleted
    case startTest
    case setEstablishment(Int)
}

let scanReducer = Reducer<ScanState, ScanAction, AppEnvironment> { state, action, environment in

    switch action {
    case .startTest:
        state.scanning = .started
        return environment.fastManager.startTest(id: FastManagerId()).fireAndForget()

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

        #if targetEnvironment(simulator)
            return Effect(value: .saveCompleted)
        #else
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
        #endif

    case .saveCompleted:
        state.scanning = .saved
        return .none

    default:
        return .none
    }
}
