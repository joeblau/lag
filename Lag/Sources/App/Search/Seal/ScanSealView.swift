//
//  ScanSealUIView.swift
//  Lag
//
//  Created by Joe Blau on 9/18/20.
//

import SwiftUI
import UIKit
import CoreLocation

struct ScanSealView: UIViewRepresentable {
    var seal: Seal
    
    func makeUIView(context: Context) -> ScanSealUIView {
        return ScanSealUIView(seal: seal)
    }

    func updateUIView(_ uiView: ScanSealUIView, context: Context) {}
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
