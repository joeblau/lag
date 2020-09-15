//
//  Constants.swift
//  Lag
//
//  Created by Joe Blau on 9/13/20.
//

import Foundation
import MapKit

struct PointOfInterest {
    let emoji: String
    let name: String
    let category: MKPointOfInterestCategory?
}

struct LocationManagerId: Hashable {}
struct FastManagerId: Hashable {}

struct Constants {
    static var scannedLocationsKey = "user_scanned_locations_key"
    static var placeholderAddress = """
    1600 Pennsylvania Avenue NW
    Washington, DC 20500
    United States
    """
    static var placeholderCoordinate = "0.000000°"
    static var placeholderSpeed =  "0.0 Kbps"
    static var placeholderPointOfInterest = "-"
    static var pointsOfInterest = [PointOfInterest(emoji: "🚫", name: "Not Point of Interest", category: nil),
                                   PointOfInterest(emoji: "🏠", name: "Rental (Airbnb, Vrbo, HomeAway)", category: nil),
                                   PointOfInterest(emoji: "🛫", name: "Airport", category: .airport),
                                   PointOfInterest(emoji: "☕️", name: "Coffee", category: .cafe),
                                   PointOfInterest(emoji: "🏨", name: "Hotel", category: .hotel),
                                   PointOfInterest(emoji: "🔋", name: "EV Charging", category: .evCharger),
                                   PointOfInterest(emoji: "📚", name: "Library", category: .library),
                                   PointOfInterest(emoji: "🏝", name: "Beach", category: .beach)]
}
