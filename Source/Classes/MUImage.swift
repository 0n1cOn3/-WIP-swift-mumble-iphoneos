// Copyright 2009-2012 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit

/// Image utility methods.
@objc(MUImage)
@objcMembers
class MUImage: NSObject {

    // MARK: - Table View Cell Images

    /// Creates a rounded-corner image scaled to 44pt height for table view cells.
    /// - Parameter srcImage: The source image to transform
    /// - Returns: A scaled image with rounded left corners
    @objc class func tableViewCellImage(from srcImage: UIImage) -> UIImage? {
        let scale = UIScreen.main.scale
        let scaledWidth = srcImage.size.width * (44.0 / srcImage.size.height)
        let rect = CGRect(x: 0, y: 0, width: scaledWidth, height: 44.0)
        let radius: CGFloat = 10.0

        // Create the rounded-rect mask (left side only)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, scale)
        guard let ctx = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }

        ctx.beginPath()
        ctx.move(to: CGPoint(x: rect.origin.x, y: rect.origin.y + radius))
        ctx.addLine(to: CGPoint(x: rect.origin.x, y: rect.origin.y + rect.size.height - radius))
        ctx.addArc(
            center: CGPoint(x: rect.origin.x + radius, y: rect.origin.y + rect.size.height - radius),
            radius: radius,
            startAngle: .pi,
            endAngle: .pi / 2,
            clockwise: true
        )
        ctx.addLine(to: CGPoint(x: rect.origin.x + rect.size.width, y: rect.origin.y + rect.size.height))
        ctx.addLine(to: CGPoint(x: rect.origin.x + rect.size.width, y: rect.origin.y))
        ctx.addLine(to: CGPoint(x: rect.origin.x + radius, y: rect.origin.y))
        ctx.addArc(
            center: CGPoint(x: rect.origin.x + radius, y: rect.origin.y + radius),
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: .pi,
            clockwise: true
        )
        ctx.closePath()
        UIColor.black.set()
        ctx.fillPath()

        guard let alphaMask = UIGraphicsGetImageFromCurrentImageContext()?.cgImage else {
            UIGraphicsEndImageContext()
            return nil
        }
        UIGraphicsEndImageContext()

        // Draw the image with the mask applied
        UIGraphicsBeginImageContextWithOptions(rect.size, false, scale)
        guard let ctx2 = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }

        ctx2.clip(to: rect, mask: alphaMask)
        srcImage.draw(in: rect)
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return scaledImage
    }

    // MARK: - Image Loading

    /// Loads an image by name, with fallback support for 4-inch (568h) screens.
    /// - Parameter imageName: The base image name without extension
    /// - Returns: The loaded image, or nil if not found
    @objc class func image(named imageName: String) -> UIImage? {
        let scale = UIScreen.main.scale
        let height = UIScreen.main.bounds.size.height

        // Legacy support for iPhone 5 (4-inch) screens
        // For now, we require all -568h images to also be @2x.
        if height == 568 && scale == 2 {
            let expectedFn = "\(imageName)-568h"
            if let attemptedImage = UIImage(named: expectedFn) {
                return attemptedImage
            }
            // fallthrough to standard image loading
        }

        return UIImage(named: imageName)
    }

    // MARK: - Utility Images

    /// Returns a 1x1 clear color image for use as a transparent background.
    /// Useful for UIKit APIs that require UIImage parameters.
    @objc class func clearColorImage() -> UIImage? {
        let fillRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(fillRect.size)
        guard let ctx = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }

        ctx.setFillColor(UIColor.clear.cgColor)
        ctx.fill(fillRect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return img
    }
}
