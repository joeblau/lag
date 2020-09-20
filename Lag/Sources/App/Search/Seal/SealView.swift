// SealView.swift
// Copyright (c) 2020 Submap

import ComposableArchitecture
import SwiftUI

struct SealView: View {
    let store: Store<ScanState, ScanAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                LazyVStack {
                    Text("Export this seal for your Airbnb, Vrbo, or HomeAway listing or share the seal on Yelp or Google Places to let other know network speeds at airports, coffee shops or libraries")
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
                    ActivityView(activityItems: [ScanSealUIView(seal: viewStore.seal).asImage()] as [Any], applicationActivities: nil) })
        }
    }
}


extension UIView {
    var renderedImage: UIImage {
        // rect of capure
        let rect = self.bounds
        // create the context of bitmap
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        let context: CGContext = UIGraphicsGetCurrentContext()!
        self.layer.render(in: context)
        // get a image from current context bitmap
        let capturedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return capturedImage
    }
}

extension View {
    func takeScreenshot(origin: CGPoint, size: CGSize) -> UIImage {
        let window = UIWindow(frame: CGRect(origin: origin, size: size))
        let hosting = UIHostingController(rootView: self)
        hosting.view.frame = window.frame
        window.addSubview(hosting.view)
        window.makeKeyAndVisible()
        return hosting.view.renderedImage
    }
}

struct SealView_Previews: PreviewProvider {
    static var previews: some View {
        SealView(store: sampleScanStore)
    }
}
