// Copyright 2013 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import Foundation

/// Processes plain text messages into HTML format for sending to Mumble servers.
/// Automatically detects and converts URLs to clickable anchor tags.
public struct TextMessageProcessor {

    public init() {}

    /// Simple URL pattern for cross-platform link detection
    private static let urlPattern = try? NSRegularExpression(
        pattern: #"https?://[^\s<>\"\']+"#,
        options: [.caseInsensitive]
    )

    /// Converts a plain text message to HTML format.
    /// Escapes HTML entities and auto-links detected URLs.
    ///
    /// - Parameter plain: The plain text message to process
    /// - Returns: HTML-formatted string, or nil if processing fails
    public static func processedHTML(from plain: String) -> String? {
        // First, ensure that the plain text string doesn't already contain HTML tags.
        // Replace < with &lt; and > with &gt;
        var str = plain.replacingOccurrences(of: "<", with: "&lt;")
        str = str.replacingOccurrences(of: ">", with: "&gt;")

        // Use regex to detect URLs (works on all platforms)
        guard let regex = urlPattern else {
            return "<p>\(str)</p>"
        }

        let matches = regex.matches(in: str, options: [], range: NSRange(location: 0, length: str.utf16.count))

        var output = "<p>"
        var lastIndex = str.startIndex

        for match in matches {
            guard let range = Range(match.range, in: str) else { continue }

            // Append text before the URL
            let beforeURL = str[lastIndex..<range.lowerBound]
            output += String(beforeURL)

            // Extract the URL and format it as an anchor tag
            let url = str[range]
            output += "<a href=\"\(url)\">\(url)</a>"

            lastIndex = range.upperBound
        }

        // Append any remaining text after the last URL
        let lastChunk = str[lastIndex...]
        output += String(lastChunk)

        output += "</p>"

        return output
    }

    /// Escapes HTML special characters in a string.
    ///
    /// - Parameter text: The text to escape
    /// - Returns: HTML-escaped string
    public static func escapeHTML(_ text: String) -> String {
        var result = text
        result = result.replacingOccurrences(of: "&", with: "&amp;")
        result = result.replacingOccurrences(of: "<", with: "&lt;")
        result = result.replacingOccurrences(of: ">", with: "&gt;")
        result = result.replacingOccurrences(of: "\"", with: "&quot;")
        result = result.replacingOccurrences(of: "'", with: "&#39;")
        return result
    }
}
