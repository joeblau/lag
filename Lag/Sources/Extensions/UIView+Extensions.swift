//
//  UIView+Extensions.swift
//  Lag
//
//  Created by Joe Blau on 9/19/20.
//

import UIKit

extension UIView {
   func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: frame.size)
        return renderer.image { context in
            layer.render(in: context.cgContext)
        }
    }
}
