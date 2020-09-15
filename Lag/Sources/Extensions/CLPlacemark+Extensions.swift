// CLPlacemark+Extensions.swift
// Copyright (c) 2020 Submap

import Contacts
import CoreLocation

extension CLPlacemark {
    var address: String? {
        guard let postalAddress = self.postalAddress else { return nil }
        let postalAddressFormatter = CNPostalAddressFormatter()
        postalAddressFormatter.style = .mailingAddress
        return postalAddressFormatter.string(from: postalAddress)
    }
}
