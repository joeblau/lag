// SampleScanReducer.swift
// Copyright (c) 2020 Submap

import AlgoliaSearchClient
import ComposableArchitecture
import Foundation

#if DEBUG

    // MARK: - Profile

    let sampleScanStore = Store(initialState: ScanState(),
                                reducer: scanReducer,
                                environment: AppEnvironment(latencyIndex: SearchClient(appID: "", apiKey: "").index(withName: ""),
                                                            locationManager: .unimplemented(),
                                                            fastManager: .mock()))
#endif
