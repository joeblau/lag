//
//  WiFiTagView.swift
//  Lag
//
//  Created by Joe Blau on 9/13/20.
//

import SwiftUI

struct WiFiTagView: View {
    let isWiFiOn: Bool
    
    var body: some View {
        
        switch isWiFiOn {
        case true:
            Label("On Wifi", systemImage: "wifi")
                .padding(EdgeInsets(top: 4, leading: 14, bottom: 4, trailing: 16))
                .foregroundColor(.white)
                .background(Color.green)
                .clipShape(Capsule(style: .continuous))
            
        case false:
            Label("Off Wifi", systemImage: "wifi.slash")
                .padding(EdgeInsets(top: 4, leading: 14, bottom: 4, trailing: 16))
                .foregroundColor(.white)
                .background(Color.red)
                .clipShape(Capsule(style: .continuous))
        }
    }
}

#if DEBUG
struct WiFiTagView_Previews: PreviewProvider {
    static var previews: some View {
        WiFiTagView(isWiFiOn: true)
            .previewLayout(.fixed(width: 200, height: 40))
        WiFiTagView(isWiFiOn: false)
            .previewLayout(.fixed(width: 200, height: 40))
    }
}
#endif
