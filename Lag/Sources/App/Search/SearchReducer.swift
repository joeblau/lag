// SearchReducer.swift
// Copyright (c) 2020 Submap

import AlgoliaSearchClient
import ComposableArchitecture
import Foundation

struct SearchResult: Equatable, Hashable {
    var pointOfInterest: String?
    var address: String = "-"
    var download: String = "-"
    var upload: String = "-"
}

// MARK: - Composable

struct SearchState: Equatable {
    var scanState = ScanState()
    var isSearching: Bool = false
    var showScanner: Bool = false
    var queryResults = [SearchResult]()
    var isEditing: Bool = false
    var queryString: String = ""
    var previousQuery: String = ""
}

enum SearchAction: Equatable {
    case presentScanner
    case dismissScanner
    case setIsEditing(Bool)
    case updateQuery(String)
    case perfomSeach(String)
    case clearQuery
    case updateResults([SearchResult])

    // Delegates
    case scanManager(ScanAction)
}

let searchReducer = Reducer<SearchState, SearchAction, AppEnvironment> { state, action, environment in
    switch action {
    case .presentScanner:
        state.scanState.scanning = .notStarted
        state.scanState.scanResult.download = nil
        state.scanState.scanResult.downloadRaw = 0.0
        state.scanState.scanResult.downloadUnits = 0
        state.scanState.scanResult.upload = nil
        state.scanState.scanResult.uploadRaw = 0.0
        state.scanState.scanResult.uploadUnits = 0
        state.showScanner = true
        return .none

    case let .setIsEditing(isEditing):
        state.isEditing = isEditing
        return .none

    case let .updateQuery(query):
        state.queryString = query
        state.isSearching = true
        struct CancelDelayId: Hashable {}

        return Effect(value: .perfomSeach(query))
            .debounce(id: CancelDelayId(),
                      for: .seconds(1),
                      scheduler: DispatchQueue.main)

    case let .perfomSeach(query):
        state.isSearching = false
        guard state.previousQuery != query else { return .none }
        state.previousQuery = query
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

    case let .updateResults(results):
        state.queryResults = results
        return .none

    case .clearQuery:
        state.isEditing = false
        state.queryString = ""
        state.previousQuery = ""
        state.queryResults = [SearchResult]()
        return .none

    // MARK: - Delegates

    case .dismissScanner,
         .scanManager(.dismissScanner):
        state.showScanner = false
        return .none

    default:
        return .none
    }
}
.combined(with: scanReducer.pullback(state: \.scanState,
                                     action: /SearchAction.scanManager,
                                     environment: { $0 }))
