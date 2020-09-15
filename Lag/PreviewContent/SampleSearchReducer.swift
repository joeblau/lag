// SampleSearchReducer.swift
// Copyright (c) 2020 Submap

import AlgoliaSearchClient
import ComposableArchitecture
import Foundation

#if DEBUG

    // MARK: - Profile

    let sampleSearchStore = Store(initialState: SearchState(),
                                  reducer: searchReducer,
                                  environment: AppEnvironment(latencyIndex: SearchClient(appID: "", apiKey: "").index(withName: ""),
                                                              locationManager: .mock(),
                                                              fastManager: .mock()))
#endif
