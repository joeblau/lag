//
//  ResultView.swift
//  Lag
//
//  Created by Joe Blau on 9/13/20.
//

import SwiftUI

struct ResultView: View {
    let result: SearchResult
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                if let poi = result.pointOfInterest {
                    Text(poi)
                        .font(.headline)
                }
                Text(result.address)
                    .font(.subheadline)
                Spacer()
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                HStack {
                    Image(systemName: "arrow.up")
                        .foregroundColor(Color(.secondaryLabel))
                        .font(Font.footnote.weight(.heavy))
                    Text(result.upload)
                }
                HStack {
                    Image(systemName: "arrow.down")
                        .foregroundColor(Color(.secondaryLabel))
                        .font(Font.footnote.weight(.heavy))
                    Text(result.download)
                }
                Spacer()
            }
            .font(.system(.subheadline, design: .monospaced))
        }
    }
}

struct ResultView_Previews: PreviewProvider {
    
    static var previews: some View {
        ResultView(result: SearchResult(pointOfInterest: "Mc Donalds",
                   address: Constants.placeholderAddress,
                   download: "10 Mbps",
                   upload: "20 Mbps"))
            .previewLayout(.fixed(width: 350, height: 120))
        
        ResultView(result: SearchResult(pointOfInterest: nil,
                   address: Constants.placeholderAddress,
                   download: "10 Mbps",
                   upload: "20 Mbps"))
            .previewLayout(.fixed(width: 350, height: 120))
        
        ResultView(result: SearchResult(pointOfInterest: "Mc Donalds",
                   address: Constants.placeholderAddress,
                   download: "10 Mbps",
                   upload: "20 Mbps"))
            .previewLayout(.fixed(width: 350, height: 120))
            .preferredColorScheme(.dark)
        
        ResultView(result: SearchResult(pointOfInterest: nil,
                   address: Constants.placeholderAddress,
                   download: "10 Mbps",
                   upload: "20 Mbps"))
            .previewLayout(.fixed(width: 350, height: 120))
            .preferredColorScheme(.dark)

    }
}
