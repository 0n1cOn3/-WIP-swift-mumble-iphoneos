// Copyright 2009-2012 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit

/// Utility class for parsing data URLs (RFC 2397).
/// Extracts binary data from base64-encoded data URLs used for embedded images.
@objc(MUDataURL)
@objcMembers
class MUDataURL: NSObject {

    /// Extracts binary data from a data URL.
    ///
    /// Expected format: `data:<mimetype>;base64,<data>`
    ///
    /// - Parameter dataURL: The data URL string to parse
    /// - Returns: The decoded data, or nil if parsing fails
    @objc(dataFromDataURL:)
    static func data(from dataURL: String) -> Data? {
        // Read: data:<mimetype>;<encoding>,<data>
        // Expect encoding = base64

        guard dataURL.hasPrefix("data:") else {
            return nil
        }

        let mimeStr = String(dataURL.dropFirst(5))

        guard let semicolonRange = mimeStr.range(of: ";") else {
            return nil
        }

        // Extract mime type (currently unused but validated)
        _ = mimeStr[..<semicolonRange.lowerBound]

        // Check for base64 encoding marker
        let afterSemicolon = mimeStr[semicolonRange.upperBound...]
        guard afterSemicolon.hasPrefix("base64,") else {
            return nil
        }

        // Extract the base64 data
        var base64data = String(afterSemicolon.dropFirst(7))

        // Clean up the base64 string
        base64data = base64data.removingPercentEncoding ?? base64data
        base64data = base64data.replacingOccurrences(of: " ", with: "")

        return Data(base64Encoded: base64data)
    }

    /// Extracts an image from a data URL.
    ///
    /// - Parameter dataURL: The data URL string containing image data
    /// - Returns: The decoded image, or nil if parsing fails
    @objc(imageFromDataURL:)
    static func image(from dataURL: String) -> UIImage? {
        guard let data = MUDataURL.data(from: dataURL) else {
            return nil
        }
        return UIImage(data: data)
    }
}
