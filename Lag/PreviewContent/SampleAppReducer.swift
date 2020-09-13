//
//  SampleAppReducer.swift
//  Latency
//
//  Created by Joe Blau on 9/11/20.
//

import Foundation
import ComposableArchitecture
import ComposableCoreLocation
import AlgoliaSearchClient

#if DEBUG
    // MARK: - Profile

    let sampleAppStore = Store(initialState: AppState(),
                               reducer: app,
                               environment: AppEnvironment(latencyIndex: SearchClient(appID: "", apiKey: "").index(withName: ""),
                                                           locationManager: .mock(),
                                                           fastManager: .mock()))
#endif
