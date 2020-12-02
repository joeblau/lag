// UIView+Extensions.swift
// Copyright (c) 2020 Submap

import UIKit

extension UIView {
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: frame.size)
        return renderer.image { context in
            layer.render(in: context.cgContext)
        }
    }
}
