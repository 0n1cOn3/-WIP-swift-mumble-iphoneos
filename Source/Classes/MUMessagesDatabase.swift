// Copyright 2009-2012 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit
import MumbleKit

/// Manages temporary storage of messages during a session.
/// Uses SQLite (via FMDB) for persistence with caching for performance.
@objc(MUMessagesDatabase)
@objcMembers
class MUMessagesDatabase: NSObject {

    // MARK: - Private Properties

    private var msgCache: NSCache<NSNumber, MUTextMessage>
    private var db: FMDatabase?
    private var messageCount: Int = 0

    // MARK: - Initialization

    override init() {
        msgCache = NSCache()
        msgCache.countLimit = 10

        super.init()

        let directory = NSTemporaryDirectory()
        let dbPath = (directory as NSString).appendingPathComponent("msg.db")

        // Remove any existing database
        try? FileManager.default.removeItem(atPath: dbPath)

        db = FMDatabase(path: dbPath)

        guard db?.open() == true else {
            NSLog("MUMessagesDatabase: Failed to open.")
            return
        }

        db?.executeUpdate(
            "CREATE TABLE IF NOT EXISTS `msg` " +
            "(`id` INTEGER PRIMARY KEY AUTOINCREMENT," +
            " `rendered` BLOB," +
            " `plist` BLOB)",
            withArgumentsIn: []
        )
    }

    // MARK: - Public Methods

    /// Adds a message to the database.
    ///
    /// - Parameters:
    ///   - msg: The MumbleKit text message to store
    ///   - heading: The heading/title for the message
    ///   - selfSent: Whether the message was sent by the local user
    @objc(addMessage:withHeading:andSentBySelf:)
    func addMessage(_ msg: MKTextMessage, withHeading heading: String, andSentBySelf selfSent: Bool) {
        var plainMsg = msg.plainTextString() ?? ""
        plainMsg = plainMsg.trimmingCharacters(in: .whitespacesAndNewlines)

        // Convert embedded images to data
        var imageDataArray: [Data] = []
        if let embeddedImages = msg.embeddedImages() as? [String] {
            for dataUrl in embeddedImages {
                if let imgData = MUDataURL.data(from: dataUrl) {
                    imageDataArray.append(imgData)
                }
            }
        }

        let dict: [String: Any] = [
            "heading": heading,
            "msg": plainMsg,
            "date": Date(),
            "links": msg.embeddedLinks() ?? [],
            "images": imageDataArray,
            "selfsent": selfSent
        ]

        do {
            let plist = try PropertyListSerialization.data(
                fromPropertyList: dict,
                format: .binary,
                options: 0
            )
            db?.executeUpdate(
                "INSERT INTO `msg` (`rendered`, `plist`) VALUES (?,?)",
                withArgumentsIn: [NSNull(), plist]
            )
            messageCount += 1
        } catch {
            db?.executeUpdate(
                "INSERT INTO `msg` (`rendered`, `plist`) VALUES (?,?)",
                withArgumentsIn: [NSNull(), NSNull()]
            )
            messageCount += 1
        }
    }

    /// Clears a message at the specified index.
    ///
    /// - Parameter row: The index of the message to clear
    @objc(clearMessageAtIndex:)
    func clearMessage(at row: Int) {
        db?.executeUpdate(
            "UPDATE `msg` SET `plist`=NULL, `rendered`=NULL WHERE `id`=?",
            withArgumentsIn: [row + 1]
        )
        msgCache.removeObject(forKey: NSNumber(value: row + 1))
    }

    /// Retrieves a message at the specified index.
    ///
    /// - Parameter row: The index of the message to retrieve
    /// - Returns: The message, or nil if not found
    @objc(messageAtIndex:)
    func message(at row: Int) -> MUTextMessage? {
        let key = NSNumber(value: row + 1)

        // Check cache first
        if let cached = msgCache.object(forKey: key) {
            return cached
        }

        // Query database
        guard let result = db?.executeQuery(
            "SELECT `plist` FROM `msg` WHERE `id` = ?",
            withArgumentsIn: [row + 1]
        ) else {
            return nil
        }

        defer { result.close() }

        guard result.next() else {
            return nil
        }

        guard let plistData = result.data(forColumnIndex: 0) else {
            return nil
        }

        guard let dict = try? PropertyListSerialization.propertyList(
            from: plistData,
            options: [],
            format: nil
        ) as? [String: Any] else {
            return nil
        }

        // Convert image data back to UIImages
        var imagesArray: [UIImage] = []
        if let imgDataArray = dict["images"] as? [Data] {
            for data in imgDataArray {
                if let image = UIImage(data: data) {
                    imagesArray.append(image)
                }
            }
        }

        let txtMsg = MUTextMessage.textMessage(
            withHeading: dict["heading"] as? String,
            andMessage: dict["msg"] as? String,
            andEmbeddedLinks: dict["links"] as? [String],
            andEmbeddedImages: imagesArray,
            andTimestampDate: dict["date"] as? Date,
            isSentBySelf: (dict["selfsent"] as? Bool) ?? false
        )

        msgCache.setObject(txtMsg, forKey: key)
        return txtMsg
    }

    /// Returns the total number of messages.
    func count() -> Int {
        return messageCount
    }
}
