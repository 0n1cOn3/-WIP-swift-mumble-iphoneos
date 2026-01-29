// Copyright 2009-2012 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import Foundation

/// Utility for parsing data URLs (RFC 2397).
/// Extracts binary data from base64-encoded data URLs used for embedded images.
public struct DataURL {

    public init() {}

    /// Result of parsing a data URL
    public struct ParseResult: Equatable {
        /// The MIME type of the data (e.g., "image/png")
        public let mimeType: String
        /// The decoded binary data
        public let data: Data

        public init(mimeType: String, data: Data) {
            self.mimeType = mimeType
            self.data = data
        }
    }

    /// Extracts binary data from a data URL.
    ///
    /// Expected format: `data:<mimetype>;base64,<data>`
    ///
    /// - Parameter dataURL: The data URL string to parse
    /// - Returns: The decoded data, or nil if parsing fails
    public static func data(from dataURL: String) -> Data? {
        return parse(dataURL)?.data
    }

    /// Parses a data URL and extracts both MIME type and data.
    ///
    /// - Parameter dataURL: The data URL string to parse
    /// - Returns: ParseResult containing MIME type and data, or nil if parsing fails
    public static func parse(_ dataURL: String) -> ParseResult? {
        // Read: data:<mimetype>;<encoding>,<data>
        // Expect encoding = base64

        guard dataURL.hasPrefix("data:") else {
            return nil
        }

        let mimeStr = String(dataURL.dropFirst(5))

        guard let semicolonRange = mimeStr.range(of: ";") else {
            return nil
        }

        // Extract mime type
        let mimeType = String(mimeStr[..<semicolonRange.lowerBound])

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

        guard let data = Data(base64Encoded: base64data) else {
            return nil
        }

        return ParseResult(mimeType: mimeType, data: data)
    }

    /// Checks if a string is a valid data URL.
    ///
    /// - Parameter string: The string to check
    /// - Returns: True if the string is a valid data URL
    public static func isDataURL(_ string: String) -> Bool {
        return parse(string) != nil
    }
}
