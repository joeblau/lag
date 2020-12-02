// ScanSealView.swift
// Copyright (c) 2020 Submap

import CoreLocation
import SwiftUI
import UIKit

struct ScanSealView: UIViewRepresentable {
    var seal: Seal

    func makeUIView(context _: Context) -> ScanSealUIView {
        ScanSealUIView(seal: seal)
    }

    func updateUIView(_: ScanSealUIView, context _: Context) {}
}

struct ScanSealView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ScanSealView(seal: Seal(addressHash: "000000000000000000000000",
                                    location: CLLocation(),
                                    downloadSpeed: "28 Mbps",
                                    uploadSpeed: "23 Mbps",
                                    supportedServices: SupportedServicesOptions([.c]),
                                    grade: .b))
                .previewLayout(.fixed(width: 1024, height: 1024))
        }
    }
}
