// SearchResultView.swift
// Copyright (c) 2020 Submap

import SwiftUI

struct SearchResultView: View {
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
                    Image(systemName: "arrow.down")
                        .foregroundColor(Color(.secondaryLabel))
                        .font(Font.footnote.weight(.heavy))
                    Text(result.download)
                }
                HStack {
                    Image(systemName: "arrow.up")
                        .foregroundColor(Color(.secondaryLabel))
                        .font(Font.footnote.weight(.heavy))
                    Text(result.upload)
                }
                Spacer()
            }
            .font(.system(.subheadline, design: .monospaced))
        }
    }
}

struct SearchResultView_Previews: PreviewProvider {
    static var previews: some View {
        SearchResultView(result: SearchResult(pointOfInterest: "Mc Donalds",
                                              address: Constants.placeholderAddress,
                                              download: "10 Mbps",
                                              upload: "20 Mbps"))
            .previewLayout(.fixed(width: 350, height: 120))

        SearchResultView(result: SearchResult(pointOfInterest: nil,
                                              address: Constants.placeholderAddress,
                                              download: "10 Mbps",
                                              upload: "20 Mbps"))
            .previewLayout(.fixed(width: 350, height: 120))

        SearchResultView(result: SearchResult(pointOfInterest: "Mc Donalds",
                                              address: Constants.placeholderAddress,
                                              download: "10 Mbps",
                                              upload: "20 Mbps"))
            .previewLayout(.fixed(width: 350, height: 120))
            .preferredColorScheme(.dark)

        SearchResultView(result: SearchResult(pointOfInterest: nil,
                                              address: Constants.placeholderAddress,
                                              download: "10 Mbps",
                                              upload: "20 Mbps"))
            .previewLayout(.fixed(width: 350, height: 120))
            .preferredColorScheme(.dark)
    }
}
