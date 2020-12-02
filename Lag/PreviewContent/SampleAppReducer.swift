// SampleAppReducer.swift
// Copyright (c) 2020 Submap

import AlgoliaSearchClient
import ComposableArchitecture
import ComposableCoreLocation
import Foundation

#if DEBUG

    // MARK: - Profile

    let sampleAppStore = Store(initialState: AppState(),
                               reducer: app,
                               environment: AppEnvironment(latencyIndex: SearchClient(appID: "", apiKey: "").index(withName: ""),
                                                           locationManager: .unimplemented(),
                                                           fastManager: .mock()))
#endif
