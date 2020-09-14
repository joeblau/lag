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
                
                ZStack {
                    Rectangle()
                        .foregroundColor(Color(.systemGroupedBackground))
                        .ignoresSafeArea()
                    
                    VStack(alignment: .leading) {
                        List {
                            Section(header: Text("Address")) {
                                ScanDataView(dataName: nil,
                                             dataValue: viewStore.scanResult.address ?? Constants.placeholderAddress,
                                             isRedacted: viewStore.scanResult.address == nil)
                            }
                            
                            Section(header: Text("Coordinate")) {
                                ScanDataView(dataName: "Latitude",
                                             dataValue: viewStore.scanResult._geoloc.flatMap { "\($0.lat)°" } ?? Constants.placeholderCoordinate,
                                             isRedacted: viewStore.scanResult._geoloc == nil)
                                ScanDataView(dataName: "Longitude",
                                             dataValue: viewStore.scanResult._geoloc.flatMap { "\($0.lng)°" } ?? Constants.placeholderCoordinate,
                                             isRedacted: viewStore.scanResult._geoloc == nil)
                            }
                            
                            Section(header: Text(viewStore.scanResult.pointOfInterest ?? Constants.placeholderPointOfInterest),
                                    footer: Text(Constants.pointsOfInterest[viewStore.establishmentPickerIndex].name)) {
                                EstablishmentPickerView(store: store)
                                    .padding(EdgeInsets(top: 0, leading: -10, bottom: 0, trailing: -10))
                            }
                            
                            Section(header: Text("Network Speed")) {
                                ScanDataView(dataName: "Download",
                                             dataValue: viewStore.scanResult.download ?? Constants.placeholderSpeed,
                                             isRedacted: viewStore.scanResult.download == nil)
                                ScanDataView(dataName: "Upload",
                                             dataValue: viewStore.scanResult.upload ?? Constants.placeholderSpeed,
                                             isRedacted: viewStore.scanResult.upload == nil)
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                        
                        switch viewStore.scanning {
                        case .notStarted:
                            Button(action: {
                                viewStore.send(.startTest)
                            }, label: {
                                Text("Scan")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.blue)
                                    .clipShape(Capsule())
                            })
                            .disabled(!viewStore.scanResult.onWiFi)
                            .opacity(viewStore.scanResult.onWiFi ? 1.0 : 0.7)
                            .padding()
                            
                        case .started:
                            ProgressView()
                                .colorScheme(.dark)
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.7))
                                .clipShape(Capsule())
                                .padding()
                            
                        case .completed, .saved:
                            Button(action: {
                                viewStore.send(.dismissScanner)
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
                }
                .navigationBarTitle("Scan")
                .navigationBarItems(leading:
                                        Button(action: {
                                            viewStore.send(.dismissScanner)
                                        }, label: {
                                            Image(systemName:"xmark")
                                                .padding()
                                        })
                                    , trailing:
                                        WiFiTagView(isWiFiOn: viewStore.scanResult.onWiFi)
                )
            })
        }
    }
}

#if DEBUG
struct ScanView_Previews: PreviewProvider {
    static var previews: some View {
        ScanView(store: sampleAppStore)
        ScanView(store: sampleAppStore)
            .preferredColorScheme(.dark)
    }
}
#endif


