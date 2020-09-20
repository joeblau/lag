// SnapshottableView.swift
// Copyright (c) 2020 Submap

import Combine
import SwiftUI
struct SnapshottableView<Content: View>: UIViewControllerRepresentable {
    private let takeSnapshotPublisher: AnyPublisher<Void, Never>
    private let handleSnapshot: (UIImage) -> Void
    private let content: () -> Content
    init(
        takeSnapshotPublisher: AnyPublisher<Void, Never>,
        handleSnapshot: @escaping (UIImage) -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.takeSnapshotPublisher = takeSnapshotPublisher
        self.handleSnapshot = handleSnapshot
        self.content = content
    }

    func makeUIViewController(context _: Context) -> SnapshottableViewController {
        SnapshottableViewController(
            rootView: content(),
            takeSnapshotPublisher: takeSnapshotPublisher,
            handleSnapshot: handleSnapshot
        )
    }

    func updateUIViewController(_: SnapshottableViewController, context _: Context) {}
    final class SnapshottableViewController: UIViewController {
        private let takeSnapshotPublisher: AnyPublisher<Void, Never>
        private let handleSnapshot: (UIImage) -> Void
        private let childViewController: UIHostingController<Content>
        private var takeSnapshotPublisherCancellable: AnyCancellable?
        init(
            rootView: Content,
            takeSnapshotPublisher: AnyPublisher<Void, Never>,
            handleSnapshot: @escaping (UIImage) -> Void
        ) {
            self.takeSnapshotPublisher = takeSnapshotPublisher
            self.handleSnapshot = handleSnapshot
            childViewController = UIHostingController(rootView: rootView)
            super.init(nibName: nil, bundle: nil)
            addChild(childViewController)
            childViewController.view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(childViewController.view)
            NSLayoutConstraint.activate([
                childViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
                childViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                childViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                childViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ])
            childViewController.didMove(toParent: self)
            takeSnapshotPublisherCancellable = takeSnapshotPublisher
                .receive(on: DispatchQueue.main)
                .map { [weak self] in self?.snapshotView() }
                .compactMap { $0 }
                .sink(receiveValue: handleSnapshot)
        }

        @available(*, unavailable)
        @objc dynamic required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func snapshotView() -> UIImage {
            let childViewControllerSize = childViewController.view.frame.size
            let snapshottableViewFrame = CGRect(origin: .zero, size: childViewControllerSize)
            return UIGraphicsImageRenderer(size: childViewControllerSize).image { _ in
                childViewController.view.drawHierarchy(
                    in: snapshottableViewFrame,
                    afterScreenUpdates: true
                )
            }
        }
    }
}
