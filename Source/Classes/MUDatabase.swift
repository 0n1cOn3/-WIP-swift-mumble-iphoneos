// Copyright 2009-2011 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import Foundation

/// SQLite database wrapper for persistent storage.
/// Uses FMDB for database operations.
@objc(MUDatabase)
@objcMembers
class MUDatabase: NSObject {

    // MARK: - Private Properties

    private static var db: FMDatabase?

    // MARK: - File Path

    private class func filePath() -> String {
        let libraryDirectories = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)
        let library = libraryDirectories[0]
        try? FileManager.default.createDirectory(atPath: library, withIntermediateDirectories: true, attributes: nil)
        return (library as NSString).appendingPathComponent("mumble.sqlite")
    }

    private class func moveOldDatabases() {
        let documentDirectories = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let docs = documentDirectories[0]
        let manager = FileManager.default

        // Hide the SQLite database from the iTunes document inspector.
        let oldPath = (docs as NSString).appendingPathComponent("mumble.sqlite")
        let newPath = (docs as NSString).appendingPathComponent(".mumble.sqlite")

        if !manager.fileExists(atPath: newPath) && manager.fileExists(atPath: oldPath) {
            do {
                try manager.moveItem(atPath: oldPath, toPath: newPath)
            } catch {
                NSLog("MUDatabase: unable to move file to new spot (mumble.sqlite -> .mumble.sqlite)")
            }
        }

        // Attempt to move an old database to the new location.
        let correctPath = filePath()
        if !manager.fileExists(atPath: correctPath) {
            let finalOldPath = newPath
            if !manager.fileExists(atPath: correctPath) && manager.fileExists(atPath: finalOldPath) {
                do {
                    try manager.moveItem(atPath: finalOldPath, toPath: correctPath)
                } catch {
                    NSLog("MUDatabase: Unable to move file to new spot (~/Documents -> ~/Library)")
                }
            }
        }
    }

    // MARK: - Initialization

    /// Initialize the database, creating tables if needed.
    @objc class func initializeDatabase() {
        NSLog("Initializing database with SQLite version: %@", FMDatabase.sqliteLibVersion() ?? "unknown")

        // Attempt to move old databases if we find ones in our old locations.
        moveOldDatabases()

        let dbPath = filePath()
        db = FMDatabase(path: dbPath)

        guard let database = db else { return }

        if database.open() {
            NSLog("MUDatabase: Initialized database at %@", dbPath)
        } else {
            NSLog("MUDatabase: Could not open database at %@", dbPath)
            db = nil
            return
        }

        database.executeUpdate("""
            CREATE TABLE IF NOT EXISTS `favourites`
            (`id` INTEGER PRIMARY KEY AUTOINCREMENT,
             `name` TEXT,
             `hostname` TEXT,
             `port` INTEGER DEFAULT 64738,
             `username` TEXT,
             `password` TEXT)
            """, withArgumentsIn: [])

        database.executeUpdate("""
            CREATE TABLE IF NOT EXISTS `cert`
            (`id` INTEGER PRIMARY KEY AUTOINCREMENT,
             `hostname` TEXT,
             `port` INTEGER,
             `digest` TEXT)
            """, withArgumentsIn: [])

        database.executeUpdate("CREATE UNIQUE INDEX IF NOT EXISTS `cert_host_port` on `cert`(`hostname`,`port`)", withArgumentsIn: [])

        database.executeUpdate("""
            CREATE TABLE IF NOT EXISTS `usernames`
            (`id` INTEGER PRIMARY KEY AUTOINCREMENT,
             `hostname` TEXT,
             `port` INTEGER,
             `username` TEXT)
            """, withArgumentsIn: [])

        database.executeUpdate("CREATE UNIQUE INDEX IF NOT EXISTS `usernames_host_port` on `usernames`(`hostname`,`port`)", withArgumentsIn: [])

        database.executeUpdate("""
            CREATE TABLE IF NOT EXISTS `tokens`
            (`id` INTEGER PRIMARY KEY AUTOINCREMENT,
             `hostname` TEXT,
             `port` INTEGER,
             `tokens` BLOB)
            """, withArgumentsIn: [])

        database.executeUpdate("CREATE UNIQUE INDEX IF NOT EXISTS `tokens_host_port` on `tokens`(`hostname`,`port`)", withArgumentsIn: [])

        database.executeUpdate("VACUUM", withArgumentsIn: [])

        if database.hadError() {
            NSLog("MUDatabase: Error: %@ (Code: %d)", database.lastErrorMessage() ?? "unknown", database.lastErrorCode())
        }
    }

    /// Tear down the database.
    @objc class func teardown() {
        db?.close()
        db = nil
    }

    // MARK: - Favourite Servers

    /// Store a single favourite server.
    @objc class func storeFavourite(_ favServ: MUFavouriteServer) {
        guard let database = db else { return }

        if favServ.hasPrimaryKey() {
            // Update existing record
            database.executeUpdate(
                "UPDATE `favourites` SET `name`=?, `hostname`=?, `port`=?, `username`=?, `password`=? WHERE `id`=?",
                withArgumentsIn: [
                    favServ.displayName ?? "",
                    favServ.hostName ?? "",
                    "\(favServ.port)",
                    favServ.userName ?? "",
                    favServ.password ?? "",
                    NSNumber(value: favServ.primaryKey)
                ]
            )
        } else {
            // Insert new record
            let newTransaction = !database.isInTransaction
            if newTransaction {
                database.beginTransaction()
            }

            database.executeUpdate(
                "INSERT INTO `favourites` (`name`, `hostname`, `port`, `username`, `password`) VALUES (?, ?, ?, ?, ?)",
                withArgumentsIn: [
                    favServ.displayName ?? "",
                    favServ.hostName ?? "",
                    "\(favServ.port)",
                    favServ.userName ?? "",
                    favServ.password ?? ""
                ]
            )

            if let res = database.executeQuery("SELECT last_insert_rowid()", withArgumentsIn: []) {
                if res.next() {
                    favServ.primaryKey = Int(res.int(forColumnIndex: 0))
                }
                res.close()
            }

            if newTransaction {
                database.commit()
            }
        }
    }

    /// Delete a favourite server.
    @objc class func deleteFavourite(_ favServ: MUFavouriteServer) {
        assert(favServ.hasPrimaryKey(), "Cannot delete a FavouriteServer not originated from the database.")
        guard let database = db else { return }
        database.executeUpdate("DELETE FROM `favourites` WHERE `id`=?", withArgumentsIn: [NSNumber(value: favServ.primaryKey)])
    }

    /// Store multiple favourite servers.
    @objc class func storeFavourites(_ favourites: [Any]) {
        guard let database = db else { return }
        database.beginTransaction()
        for case let favServ as MUFavouriteServer in favourites {
            storeFavourite(favServ)
        }
        database.commit()
    }

    /// Fetch all favourite servers.
    @objc class func fetchAllFavourites() -> NSMutableArray {
        let favs = NSMutableArray()
        guard let database = db else { return favs }

        if let res = database.executeQuery(
            "SELECT `id`, `name`, `hostname`, `port`, `username`, `password` FROM `favourites`",
            withArgumentsIn: []
        ) {
            while res.next() {
                let fs = MUFavouriteServer()
                fs.primaryKey = Int(res.int(forColumnIndex: 0))
                fs.displayName = res.string(forColumnIndex: 1)
                fs.hostName = res.string(forColumnIndex: 2)
                fs.port = UInt(res.int(forColumnIndex: 3))
                fs.userName = res.string(forColumnIndex: 4)
                fs.password = res.string(forColumnIndex: 5)
                favs.add(fs)
            }
            res.close()
        }

        return favs
    }

    // MARK: - Certificate Verification

    /// Store a certificate digest for a server.
    @objc class func storeDigest(_ hash: String, forServerWithHostname hostname: String, port: Int) {
        guard let database = db else { return }
        database.executeUpdate(
            "REPLACE INTO `cert` (`hostname`,`port`,`digest`) VALUES (?,?,?)",
            withArgumentsIn: [hostname, NSNumber(value: port), hash]
        )
    }

    /// Retrieve the stored certificate digest for a server.
    @objc class func digestForServer(withHostname hostname: String, port: Int) -> String? {
        guard let database = db else { return nil }
        if let result = database.executeQuery(
            "SELECT `digest` FROM `cert` WHERE `hostname` = ? AND `port` = ?",
            withArgumentsIn: [hostname, NSNumber(value: port)]
        ) {
            if result.next() {
                let digest = result.string(forColumnIndex: 0)
                result.close()
                return digest
            }
            result.close()
        }
        return nil
    }

    // MARK: - Username Storage

    /// Store a username for a server.
    @objc class func storeUsername(_ username: String, forServerWithHostname hostname: String, port: Int) {
        guard let database = db else { return }
        database.executeUpdate(
            "REPLACE INTO `usernames` (`hostname`,`port`,`username`) VALUES (?,?,?)",
            withArgumentsIn: [hostname, NSNumber(value: port), username]
        )
    }

    /// Retrieve the stored username for a server.
    @objc class func usernameForServer(withHostname hostname: String, port: Int) -> String? {
        guard let database = db else { return nil }
        if let result = database.executeQuery(
            "SELECT `username` FROM `usernames` WHERE `hostname` = ? AND `port` = ?",
            withArgumentsIn: [hostname, NSNumber(value: port)]
        ) {
            if result.next() {
                let username = result.string(forColumnIndex: 0)
                result.close()
                return username
            }
            result.close()
        }
        return nil
    }

    // MARK: - Access Tokens

    /// Store access tokens for a server.
    @objc class func storeAccessTokens(_ tokens: [Any]?, forServerWithHostname hostname: String, port: Int) {
        guard let database = db else { return }

        var tokensJSON: Data? = nil
        if let tokens = tokens {
            do {
                tokensJSON = try JSONSerialization.data(withJSONObject: tokens, options: [])
            } catch {
                NSLog("MUDatabase#storeAccessTokens:forServerWithHostname:port: %@", error.localizedDescription)
                return
            }
        }

        database.executeUpdate(
            "REPLACE INTO `tokens` (`hostname`,`port`,`tokens`) VALUES (?,?,?)",
            withArgumentsIn: [hostname, NSNumber(value: port), tokensJSON as Any]
        )
    }

    /// Retrieve access tokens for a server.
    @objc class func accessTokensForServer(withHostname hostname: String, port: Int) -> [Any]? {
        guard let database = db else { return nil }

        if let result = database.executeQuery(
            "SELECT `tokens` FROM `tokens` WHERE `hostname` = ? AND `port` = ?",
            withArgumentsIn: [hostname, NSNumber(value: port)]
        ) {
            if result.next() {
                if let tokensJSON = result.data(forColumnIndex: 0) {
                    result.close()
                    do {
                        let tokens = try JSONSerialization.jsonObject(with: tokensJSON, options: [])
                        return tokens as? [Any]
                    } catch {
                        NSLog("MUDatabase#accessTokensForServerWithHostname:port: %@", error.localizedDescription)
                        return nil
                    }
                }
            }
            result.close()
        }
        return nil
    }
}
