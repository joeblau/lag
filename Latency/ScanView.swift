//
//  ScanView.swift
//  Latency
//
//  Created by Joe Blau on 9/11/20.
//

import SwiftUI
import ComposableArchitecture

struct ScanView: View {
    let store: Store<AppState, AppAction>

    var body: some View {
        WithViewStore(store) { viewStore in
            NavigationView(content: {
                VStack(alignment: .leading) {
                    VStack {
                        Text("Submit a scan at your current location to search.")
                        switch viewStore.scanResult.onWiFi {
                        case true: Label("On Wifi", systemImage: "wifi").foregroundColor(.green)
                        case false: Label("Off Wifi", systemImage: "wifi.slash").foregroundColor(.red)
                        }
                    }
                    .padding()

                    List {
                        Section(header: Text("Address")) {
                            Text(viewStore.scanResult.address)
                                .font(.system(.subheadline, design: .monospaced))
                        }
                        
                        Section(header: Text("Coordinate")) {
                            Text("Lat: \(viewStore.scanResult._geoloc.lat)")
                                .font(.system(.subheadline, design: .monospaced))
                            Text("Lng: \(viewStore.scanResult._geoloc.lng)")
                                .font(.system(.subheadline, design: .monospaced))
                        }
                        
                        Section(header: Text("Download")) {
                            Text("\(viewStore.scanResult.download)")
                                .font(.system(.subheadline, design: .monospaced))
                        }
                        
                        
                        Section(header: Text("Upload")) {
                            Text("\(viewStore.scanResult.upload)")
                                .font(.system(.subheadline, design: .monospaced))
                        }
                    }
                    .listStyle(PlainListStyle())
                    
                    switch viewStore.scanning {
                    case .notStarted, .started:
                        Button(action: {
                            viewStore.send(.startScannerDownload)
                        }, label: {
                            Text("Scan")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .clipShape(Capsule())
                        })
                        .padding()
                        .opacity(viewStore.scanning == .started ? 0.7 : 1.0)
                        .disabled(viewStore.scanning == .started)
                    case .completed, .saved:
                        Button(action: {
                            viewStore.send(.forceDismissScanner)
                        }, label: {
                            Text("Completed")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                                .padding()
                                .background(viewStore.scanning == .saved ? Color.green : Color.blue)
                                .clipShape(Capsule())
                        })
                        .padding()
                    }

                    
                }
                .navigationBarTitle("Scan")
                .navigationBarItems(leading:
                                    Button(action: {
                                        viewStore.send(.forceDismissScanner)
                                    }, label: {
                                        Image(systemName:"xmark")
                                    })

                )
            })
        }
    }
}

#if DEBUG
struct ScanView_Previews: PreviewProvider {
    static var previews: some View {
        ScanView(store: sampleAppStore)
    }
}
#endif
