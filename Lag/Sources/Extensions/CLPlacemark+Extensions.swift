//
//  CLPlacemark+Extensions.swift
//  Lag
//
//  Created by Joe Blau on 9/14/20.
//

import CoreLocation
import Contacts

extension CLPlacemark {
    var address: String? {
        guard let postalAddress = self.postalAddress else { return nil }
        let postalAddressFormatter = CNPostalAddressFormatter()
        postalAddressFormatter.style = .mailingAddress
        return postalAddressFormatter.string(from: postalAddress)
    }
}
