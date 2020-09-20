// ActivityView.swift
// Copyright (c) 2020 Submap

import SwiftUI
import UIKit

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]?

    func makeUIViewController(context _: UIViewControllerRepresentableContext<ActivityView>) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems,
                                 applicationActivities: applicationActivities)
    }

    func updateUIViewController(_: UIActivityViewController,
                                context _: UIViewControllerRepresentableContext<ActivityView>) {}
}
