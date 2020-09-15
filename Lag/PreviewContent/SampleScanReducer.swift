//
//  SampleScanReducer.swift
//  Lag
//
//  Created by Joe Blau on 9/14/20.
//

import Foundation
import ComposableArchitecture
import AlgoliaSearchClient

#if DEBUG
    // MARK: - Profile

    let sampleScanStore = Store(initialState: ScanState(),
                               reducer: scanReducer,
                               environment: AppEnvironment(latencyIndex: SearchClient(appID: "", apiKey: "").index(withName: ""),
                                                           locationManager: .mock(),
                                                           fastManager: .mock()))
#endif
