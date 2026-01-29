// Copyright 2009-2012 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import Foundation

/// Represents a processed text message with heading, content, and attachments.
/// Used for displaying messages in the messages view.
public struct TextMessage: Equatable {

    // MARK: - Properties

    /// The heading/title of the message (e.g., "From User" or "To Channel")
    public let heading: String?

    /// The message content
    public let message: String?

    /// The timestamp when the message was received/sent
    public let date: Date?

    /// URLs embedded in the message
    public let embeddedLinks: [String]

    /// Number of embedded images
    public let embeddedImageCount: Int

    /// Whether the message was sent by the local user
    public let isSentBySelf: Bool

    // MARK: - Initialization

    public init(
        heading: String?,
        message: String?,
        date: Date? = nil,
        embeddedLinks: [String] = [],
        embeddedImageCount: Int = 0,
        isSentBySelf: Bool = false
    ) {
        self.heading = heading
        self.message = message
        self.date = date
        self.embeddedLinks = embeddedLinks
        self.embeddedImageCount = embeddedImageCount
        self.isSentBySelf = isSentBySelf
    }

    // MARK: - Computed Properties

    /// Total number of attachments (links + images)
    public var numberOfAttachments: Int {
        return embeddedLinks.count + embeddedImageCount
    }

    /// Whether the message has any attachments
    public var hasAttachments: Bool {
        return numberOfAttachments > 0
    }
}
