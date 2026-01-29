// Copyright 2009-2011 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit

/// Application color constants.
@objc(MUColor)
@objcMembers
class MUColor: NSObject {

    // MARK: - Text Colors

    /// Selected text color (#5d5d5d)
    @objc class func selectedTextColor() -> UIColor {
        return UIColor(red: 0x5d/255.0, green: 0x5d/255.0, blue: 0x5d/255.0, alpha: 1.0)
    }

    // MARK: - Ping Status Colors

    /// Good ping indicator color (#609a4b - green)
    @objc class func goodPingColor() -> UIColor {
        return UIColor(red: 0x60/255.0, green: 0x9a/255.0, blue: 0x4b/255.0, alpha: 1.0)
    }

    /// Medium ping indicator color (#F2DE69 - yellow)
    @objc class func mediumPingColor() -> UIColor {
        return UIColor(red: 0xf2/255.0, green: 0xde/255.0, blue: 0x69/255.0, alpha: 1.0)
    }

    /// Bad ping indicator color (#D14D54 - red)
    @objc class func badPingColor() -> UIColor {
        return UIColor(red: 0xd1/255.0, green: 0x4d/255.0, blue: 0x54/255.0, alpha: 1.0)
    }

    // MARK: - Server Status Colors

    /// User count text color
    @objc class func userCountColor() -> UIColor {
        return .darkGray
    }

    // MARK: - Certificate Colors

    /// Background color for verified certificate chain (#dfffdf - light green)
    @objc class func verifiedCertificateChainColor() -> UIColor {
        return UIColor(red: 0xdf/255.0, green: 1.0, blue: 0xdf/255.0, alpha: 1.0)
    }

    // MARK: - Background Colors

    /// Background color for iOS 7+ style views (#1c1c1c - dark gray)
    @objc class func backgroundViewiOS7Color() -> UIColor {
        return UIColor(red: 0x1c/255.0, green: 0x1c/255.0, blue: 0x1c/255.0, alpha: 1.0)
    }

    /// Alias for backgroundViewiOS7Color for use in Swift code
    @objc class func backgroundViewiOS7() -> UIColor {
        return backgroundViewiOS7Color()
    }

    // MARK: - Short Aliases (for callers using short names)

    @objc class func selectedText() -> UIColor {
        return selectedTextColor()
    }

    @objc class func goodPing() -> UIColor {
        return goodPingColor()
    }

    @objc class func mediumPing() -> UIColor {
        return mediumPingColor()
    }

    @objc class func badPing() -> UIColor {
        return badPingColor()
    }

    @objc class func userCount() -> UIColor {
        return userCountColor()
    }

    @objc class func verifiedCertificateChain() -> UIColor {
        return verifiedCertificateChainColor()
    }
}
