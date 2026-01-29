// Copyright 2009-2010 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import Foundation

/// Model representing a favourite (saved) server in the user's server list.
/// Stores connection details and database primary key for persistence.
@objc(MUFavouriteServer)
@objcMembers
class MUFavouriteServer: NSObject, NSCopying {

    /// Database primary key. -1 indicates the server has not been persisted yet.
    var primaryKey: Int = -1

    /// User-facing display name for the server
    var displayName: String?

    /// Server hostname or IP address
    var hostName: String?

    /// Server port (Mumble default is 64738)
    var port: UInt = 0

    /// Username to connect with
    var userName: String?

    /// Server password (if required)
    var password: String?

    // MARK: - Initializers

    override init() {
        super.init()
    }

    @objc(initWithDisplayName:hostName:port:userName:password:)
    init(displayName: String?, hostName: String?, port: UInt, userName: String?, password: String?) {
        self.primaryKey = -1
        self.displayName = displayName
        self.hostName = hostName
        self.port = port
        self.userName = userName
        self.password = password
        super.init()
    }

    // MARK: - Primary Key

    /// Returns true if this server has been saved to the database
    func hasPrimaryKey() -> Bool {
        return primaryKey != -1
    }

    // MARK: - NSCopying

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = MUFavouriteServer(
            displayName: displayName,
            hostName: hostName,
            port: port,
            userName: userName,
            password: password
        )
        if hasPrimaryKey() {
            copy.primaryKey = primaryKey
        }
        return copy
    }

    // MARK: - Comparison

    /// Compare servers by display name (case-insensitive) for sorting
    @objc(compare:)
    func compare(_ other: MUFavouriteServer) -> ComparisonResult {
        guard let myName = displayName else {
            return other.displayName == nil ? .orderedSame : .orderedAscending
        }
        guard let otherName = other.displayName else {
            return .orderedDescending
        }
        return myName.caseInsensitiveCompare(otherName)
    }
}
