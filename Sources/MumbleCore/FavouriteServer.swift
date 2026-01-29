// Copyright 2009-2010 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import Foundation

/// Model representing a favourite (saved) server in the user's server list.
/// Stores connection details and database primary key for persistence.
public struct FavouriteServer: Equatable, Codable {

    /// Database primary key. -1 indicates the server has not been persisted yet.
    public var primaryKey: Int

    /// User-facing display name for the server
    public var displayName: String?

    /// Server hostname or IP address
    public var hostName: String?

    /// Server port (Mumble default is 64738)
    public var port: UInt

    /// Username to connect with
    public var userName: String?

    /// Server password (if required)
    public var password: String?

    // MARK: - Initializers

    public init(
        primaryKey: Int = -1,
        displayName: String? = nil,
        hostName: String? = nil,
        port: UInt = 64738,
        userName: String? = nil,
        password: String? = nil
    ) {
        self.primaryKey = primaryKey
        self.displayName = displayName
        self.hostName = hostName
        self.port = port
        self.userName = userName
        self.password = password
    }

    // MARK: - Primary Key

    /// Returns true if this server has been saved to the database
    public var hasPrimaryKey: Bool {
        return primaryKey != -1
    }

    // MARK: - Comparison

    /// Compare servers by display name (case-insensitive) for sorting
    public func compare(_ other: FavouriteServer) -> ComparisonResult {
        guard let myName = displayName else {
            return other.displayName == nil ? .orderedSame : .orderedAscending
        }
        guard let otherName = other.displayName else {
            return .orderedDescending
        }
        return myName.caseInsensitiveCompare(otherName)
    }
}

// MARK: - Comparable

extension FavouriteServer: Comparable {
    public static func < (lhs: FavouriteServer, rhs: FavouriteServer) -> Bool {
        return lhs.compare(rhs) == .orderedAscending
    }
}
