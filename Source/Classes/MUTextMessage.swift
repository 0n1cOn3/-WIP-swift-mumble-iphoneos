// Copyright 2009-2012 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import Foundation

/// Represents a processed text message with heading, content, and attachments.
/// Used for displaying messages in the messages view.
@objc(MUTextMessage)
@objcMembers
class MUTextMessage: NSObject {

    // MARK: - Properties

    private let _heading: String?
    private let _message: String?
    private let _date: Date?
    private let _links: [String]
    private let _images: [Any]  // Can be UIImage or Data
    private let _sentBySelf: Bool

    // MARK: - Initialization

    private init(
        heading: String?,
        message: String?,
        date: Date?,
        links: [String]?,
        images: [Any]?,
        sentBySelf: Bool
    ) {
        self._heading = heading
        self._message = message
        self._date = date
        self._links = links ?? []
        self._images = images ?? []
        self._sentBySelf = sentBySelf
        super.init()
    }

    /// Factory method to create a text message
    @objc(textMessageWithHeading:andMessage:andEmbeddedLinks:andEmbeddedImages:andTimestampDate:isSentBySelf:)
    static func textMessage(
        withHeading heading: String?,
        andMessage message: String?,
        andEmbeddedLinks links: [String]?,
        andEmbeddedImages images: [Any]?,
        andTimestampDate date: Date?,
        isSentBySelf sentBySelf: Bool
    ) -> MUTextMessage {
        return MUTextMessage(
            heading: heading,
            message: message,
            date: date,
            links: links,
            images: images,
            sentBySelf: sentBySelf
        )
    }

    // MARK: - Accessors

    /// The heading/title of the message (e.g., "From User" or "To Channel")
    func heading() -> String? {
        return _heading
    }

    /// The message content
    func message() -> String? {
        return _message
    }

    /// The timestamp when the message was received/sent
    func date() -> Date? {
        return _date
    }

    /// URLs embedded in the message
    func embeddedLinks() -> [String] {
        return _links
    }

    /// Images embedded in the message
    func embeddedImages() -> [Any] {
        return _images
    }

    /// Total number of attachments (links + images)
    func numberOfAttachments() -> Int {
        return _links.count + _images.count
    }

    /// Whether the message has any attachments
    func hasAttachments() -> Bool {
        return numberOfAttachments() > 0
    }

    /// Whether the message was sent by the local user
    func isSentBySelf() -> Bool {
        return _sentBySelf
    }
}
