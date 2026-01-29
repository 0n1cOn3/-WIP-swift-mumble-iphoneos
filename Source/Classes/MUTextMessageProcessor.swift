// Copyright 2013 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import Foundation

/// Processes plain text messages into HTML format for sending to Mumble servers.
/// Automatically detects and converts URLs to clickable anchor tags.
@objc(MUTextMessageProcessor)
@objcMembers
class MUTextMessageProcessor: NSObject {

    /// Converts a plain text message to HTML format.
    /// Escapes HTML entities and auto-links detected URLs.
    ///
    /// - Parameter plain: The plain text message to process
    /// - Returns: HTML-formatted string, or nil if processing fails
    @objc(processedHTMLFromPlainTextMessage:)
    static func processedHTML(fromPlainTextMessage plain: String) -> String? {
        // First, ensure that the plain text string doesn't already contain HTML tags.
        // Replace < with &lt; and > with &gt;
        var str = plain.replacingOccurrences(of: "<", with: "&lt;")
        str = str.replacingOccurrences(of: ">", with: "&gt;")

        // Use NSDataDetector to detect any links in the message and
        // automatically convert them to <a>-tags.
        do {
            let linkDetector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            let matches = linkDetector.matches(in: str, options: [], range: NSRange(location: 0, length: str.utf16.count))

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

        } catch {
            // If data detector fails, return simple paragraph-wrapped text
            return "<p>\(str)</p>"
        }
    }
}
