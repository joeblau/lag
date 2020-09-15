//
//  SampleSearchReducer.swift
//  Lag
//
//  Created by Joe Blau on 9/14/20.
//

import Foundation
import ComposableArchitecture
import AlgoliaSearchClient

#if DEBUG
    // MARK: - Profile

    let sampleSearchStore = Store(initialState: SearchState(),
                               reducer: searchReducer,
                               environment: AppEnvironment(latencyIndex: SearchClient(appID: "", apiKey: "").index(withName: ""),
                                                           locationManager: .mock(),
                                                           fastManager: .mock()))
#endif
