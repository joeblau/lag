//
//  LatencyApp.swift
//  Latency
//
//  Created by Joe Blau on 9/11/20.
//

import SwiftUI
import Logging
import ComposableArchitecture
import AlgoliaSearchClient

let logger = Logger(label: "com.joeblau.Latency")

@main
struct LagApp: App {
    @Environment(\.scenePhase) private var scenePhase

    let store = Store<AppState, AppAction>(initialState: AppState(),
                                           reducer: app,
                                           environment: AppEnvironment(latencyIndex: SearchClient(appID: "IYADMQFILK", apiKey: "5cc77b4a1a6f08aaeffa9130bf0917d5")
                                                                        .index(withName: "prod_LATENCY"),
                                                                       locationManager: .live,
                                                                       fastManager: .live))
    
    var body: some Scene {
        WindowGroup {
            SearchView(store: store.scope(state: { $0.searchState },
                                          action: { AppAction.searchManager($0) }))
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .background:
                ViewStore(store).send(.onBackground)
            case .inactive:
                ViewStore(store).send(.onInactive)
            case .active:
                ViewStore(store).send(.onActive)
            @unknown default:
                logger.error("invalid scene phase")
            }
        }
    }
}
