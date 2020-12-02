// SealView.swift
// Copyright (c) 2020 Submap

import ComposableArchitecture
import SwiftUI
import UIKit

struct SealView: View {
    let store: Store<ScanState, ScanAction>

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                LazyVStack {
                    Text("This seal helps people know what network speeds to expect at your coffee shop, library, or airport. It’s great for Yelp listings, and Airbnb hosts too.")
                        .padding(.horizontal, 10)
                    ScanSealView(seal: viewStore.seal)
                        .scaleEffect(0.25)
                        .padding(.horizontal, -300)
                }
                Spacer()

                Button(action: {
                    viewStore.send(.exportSeal)
                }, label: {
                    Text("Export")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .clipShape(Capsule())
                })
                    .padding()
            }
            .navigationBarTitle("Speed Seal")
            .sheet(isPresented: viewStore.binding(get: { $0.showShareSheet }, send: .dismissShareSheet), content: {
                ActivityView(activityItems: [ScanSealUIView(seal: viewStore.seal).asImage().pngData()!] as [Any], applicationActivities: nil)
            })
        }
    }
}

#if DEBUG
    struct SealView_Previews: PreviewProvider {
        static var previews: some View {
            SealView(store: sampleScanStore)
        }
    }
#endif
