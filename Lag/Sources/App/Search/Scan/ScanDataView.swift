//
//  ScanDataView.swift
//  Lag
//
//  Created by Joe Blau on 9/13/20.
//

import SwiftUI

struct ScanDataView: View {
    let dataName: String?
    let dataValue: String
    let isRedacted: Bool
    
        var body: some View {
            HStack {
                if let name = dataName {
                    Text(name)
                    Spacer()
                }
                switch isRedacted {
                case true: Text(dataValue).redacted(reason: .placeholder)
                case false: Text(dataValue)
                }
            }
            .font(.system(.subheadline, design: .monospaced))
        }
}

struct ScanDataView_Previews: PreviewProvider {
    static var previews: some View {
        ScanDataView(dataName: "Latitude", dataValue: "13.93255°", isRedacted: false)
            .previewLayout(.fixed(width: 320, height: 60))
        ScanDataView(dataName: "Latitude", dataValue: "13.93255°", isRedacted: true)
            .previewLayout(.fixed(width: 320, height: 60))
    }
}

