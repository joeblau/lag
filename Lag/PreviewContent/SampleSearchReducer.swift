// SampleSearchReducer.swift
// Copyright (c) 2020 Submap

import AlgoliaSearchClient
import ComposableArchitecture
import Foundation

#if DEBUG

    let queryResults = [SearchResult(pointOfInterest: "Philz Coffee", address: "123 Main Street\nSan Francisco, CA", download: "124 Mbps", upload: "92 Mbps")]

    // MARK: - Profile

    let sampleSearchStore = Store(initialState: SearchState(queryResults: queryResults),
                                  reducer: searchReducer,
                                  environment: AppEnvironment(latencyIndex: SearchClient(appID: "", apiKey: "").index(withName: ""),
                                                              locationManager: .mock(),
                                                              fastManager: .mock()))
#endif
