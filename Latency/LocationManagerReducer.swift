//
//  LocationManagerReducer.swift
//  Latency
//
//  Created by Joe Blau on 9/11/20.
//

import Foundation
import ComposableArchitecture
import ComposableCoreLocation

let locationManager = Reducer<AppState, LocationManager.Action, AppEnvironment> { _, _, _ in
    return .none
}
