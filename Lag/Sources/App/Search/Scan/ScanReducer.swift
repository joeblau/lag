// ScanReducer.swift
// Copyright (c) 2020 Submap

import AlgoliaSearchClient
import ComposableArchitecture
import CoreLocation
import CryptoKit
import Foundation
import UIKit

struct SupportedServicesOptions: OptionSet, Equatable {
    let rawValue: Int

    static let email = SupportedServicesOptions(rawValue: 1 << 0)
    static let audio = SupportedServicesOptions(rawValue: 1 << 1)
    static let web = SupportedServicesOptions(rawValue: 1 << 2)
    static let sdVideo = SupportedServicesOptions(rawValue: 1 << 3)
    static let oneToOneVideoCall = SupportedServicesOptions(rawValue: 1 << 4)
    static let oneToManyVideoCall = SupportedServicesOptions(rawValue: 1 << 5)
    static let socialMedia = SupportedServicesOptions(rawValue: 1 << 6)
    static let hdVideo = SupportedServicesOptions(rawValue: 1 << 7)
    static let gaming = SupportedServicesOptions(rawValue: 1 << 8)
    static let kkkkVideo = SupportedServicesOptions(rawValue: 1 << 9)

    static let na: SupportedServicesOptions = []
    static let f: SupportedServicesOptions = [.email, .audio]
    static let d: SupportedServicesOptions = [.email, .audio, .web, .sdVideo, .oneToOneVideoCall]
    static let c: SupportedServicesOptions = [.email, .audio, .web, .sdVideo, .oneToOneVideoCall, .oneToManyVideoCall, .socialMedia, .hdVideo]
    static let b: SupportedServicesOptions = [.email, .audio, .web, .sdVideo, .oneToOneVideoCall, .oneToManyVideoCall, .socialMedia, .hdVideo, .gaming]
    static let a: SupportedServicesOptions = [.email, .audio, .web, .sdVideo, .oneToOneVideoCall, .oneToManyVideoCall, .socialMedia, .hdVideo, .gaming, .kkkkVideo]
}

enum ScanningState: Equatable {
    case notStarted
    case started
    case completed
    case saved
    case error
}

enum Grade: Equatable, CustomStringConvertible {
    case a
    case b
    case c
    case d
    case f

    var description: String {
        switch self {
        case .a: return "A"
        case .b: return "B"
        case .c: return "C"
        case .d: return "D"
        case .f: return "F"
        }
    }
}

struct Seal: Equatable {
    var addressHash: String = "0000000000000000000000000000000000000000"
    var location = CLLocation()
    var downloadSpeed: String = "-"
    var uploadSpeed: String = "-"
    var supportedServices = SupportedServicesOptions()
    var grade: Grade = .f
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
    var showShareSheet: Bool = false
    var establishmentPickerIndex = 0
    var scanning: ScanningState = .notStarted
    var scanResult = ScanResult(objectID: ObjectID(stringLiteral: UUID().uuidString))
    var location: CLLocation?
    var seal = Seal()
    var sealRect: CGRect = .zero
    var publicSeal: UIImage?
}

enum ScanAction: Equatable {
    case dismissScanner
    case dismissShareSheet

    case exportSeal
    case startSaveResults
    case saveError
    case saveCompleted
    case startTest
    case setEstablishment(Int)
}

let scanReducer = Reducer<ScanState, ScanAction, AppEnvironment> { state, action, environment in

    switch action {
    case .startTest:
        UIApplication.shared.isIdleTimerDisabled = true
        state.scanning = .started
        return environment.fastManager.startTest(id: FastManagerId()).fireAndForget()

    case .startSaveResults:
        UIApplication.shared.isIdleTimerDisabled = false
        guard state.scanResult.download != nil, state.scanResult.upload != nil else {
            return .merge(
                environment.fastManager.stopTest(id: FastManagerId()).fireAndForget(),
                Effect(value: .saveError)
            )
        }

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

//        #if targetEnvironment(simulator)
        return Effect(value: .saveCompleted)
//        #else
//            return .future { completion in
//                environment.latencyIndex.saveObjects(scanResults, autoGeneratingObjectID: true) { result in
//                    switch result {
//                    case let .success(response):
//                        completion(.success(.saveCompleted))
//                    case let .failure(error):
//                        logger.error("\(error.localizedDescription)")
//                    }
//                }
//            }
//        #endif

    case .saveError:
        state.scanning = .error
        return .none

    case .exportSeal:
        state.showShareSheet = true
        return .none

    case .dismissShareSheet:
        state.showShareSheet = false
        return .none

    case .saveCompleted:
        state.scanning = .saved

        guard let location = state.location,
            let downloadSpeed = state.scanResult.download,
            let uploadSpeed = state.scanResult.upload
        else {
            return .none
        }

        let addressHash = state.scanResult.objectID.rawValue

        let grade: Grade
        let supportedServcies: SupportedServicesOptions

        switch state.scanResult.downloadUnits {
        case 1:
            switch state.scanResult.downloadRaw {
            case 0 ..< 1:
                grade = .f
                supportedServcies = .f
            case 1 ..< 5:
                grade = .d
                supportedServcies = .d
            case 5 ..< 10:
                grade = .c
                supportedServcies = .c
            case 10 ..< 25:
                grade = .b
                supportedServcies = .b
            default:
                grade = .a
                supportedServcies = .a
            }
        case 2:
            grade = .a
            supportedServcies = .a
        default:
            grade = .f
            supportedServcies = .na
        }

        state.seal = Seal(addressHash: state.scanResult.objectID.rawValue,
                          location: location,
                          downloadSpeed: downloadSpeed,
                          uploadSpeed: uploadSpeed,
                          supportedServices: supportedServcies,
                          grade: grade)
        return .none

    default:
        return .none
    }
}
