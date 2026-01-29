// Copyright 2009-2010 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import Foundation
import MumbleKit

/// Fetches the latest public server list XML from Mumble's regional server list URL.
@objc(MUPublicServerListFetcher)
@objcMembers
class MUPublicServerListFetcher: NSObject {

    override init() {
        super.init()
    }

    /// Attempts to download the latest server list and save it to disk.
    func attemptUpdate() {
        guard let url = MKServices.regionalServerListURL() else {
            return
        }
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard error == nil, let data = data else {
                return
            }
            try? data.write(to: URL(fileURLWithPath: MUPublicServerList.filePath()))
        }.resume()
    }
}

/// Parses and provides access to the Mumble public server directory.
/// Organizes servers by continent and country for hierarchical display.
@objc(MUPublicServerList)
@objcMembers
class MUPublicServerList: NSObject, XMLParserDelegate {

    // MARK: - File Path

    /// Returns the path where the server list XML is cached
    @objc static func filePath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)
        let directory = paths[0]
        try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        return (directory as NSString).appendingPathComponent("publist.xml")
    }

    // MARK: - Private Properties

    private var serverListXML: Data?
    private var continentCountries: [String: Set<String>] = [:]
    private var countryServers: [String: [[String: String]]] = [:]
    private var continentNames: [String: String] = [:]
    private var countryNames: [String: String] = [:]
    private var modelContinents: [String] = []
    private var modelCountries: [[[String: Any]]] = []
    private var parsed: Bool = false

    // MARK: - Initialization

    override init() {
        super.init()

        // Load XML from cached file or fall back to bundled default
        let cachedPath = MUPublicServerList.filePath()
        if FileManager.default.fileExists(atPath: cachedPath) {
            serverListXML = try? Data(contentsOf: URL(fileURLWithPath: cachedPath))
        } else if let bundledPath = Bundle.main.path(forResource: "publist", ofType: "xml") {
            serverListXML = try? Data(contentsOf: URL(fileURLWithPath: bundledPath))
        }

        // Load continent and country name mappings from bundled plists
        let resourcePath = Bundle.main.resourcePath ?? ""
        if let continents = NSDictionary(contentsOfFile: "\(resourcePath)/Continents.plist") as? [String: String] {
            continentNames = continents
        }
        if let countries = NSDictionary(contentsOfFile: "\(resourcePath)/Countries.plist") as? [String: String] {
            countryNames = countries
        }
    }

    // MARK: - Parsing

    /// Parses the XML server list and builds the continent/country model.
    /// Call this before accessing any model data.
    func parse() {
        guard !parsed else { return }
        guard let xmlData = serverListXML else { return }

        continentCountries = [:]
        countryServers = [:]

        // Parse XML
        let parser = XMLParser(data: xmlData)
        parser.delegate = self
        parser.parse()

        // Transform dictionary representation to array model
        let continentCodes = continentNames.keys.sorted()
        modelContinents = []
        modelCountries = []

        for continentCode in continentCodes {
            if let continentName = continentNames[continentCode] {
                modelContinents.append(continentName)
            }

            let countryCodeSet = continentCountries[continentCode] ?? []
            let countryCodes = countryCodeSet.sorted()

            var countries: [[String: Any]] = []
            for countryCode in countryCodes {
                let countryName = countryNames[countryCode] ?? countryCode
                let servers = countryServers[countryCode] ?? []
                let country: [String: Any] = [
                    "name": countryName,
                    "servers": servers
                ]
                countries.append(country)
            }
            modelCountries.append(countries)
        }

        parsed = true
    }

    // MARK: - XMLParserDelegate

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?,
        attributes: [String: String]
    ) {
        guard elementName == "server" else { return }
        guard let countryCode = attributes["country_code"] else { return }

        // Add server to country's server list
        if countryServers[countryCode] == nil {
            countryServers[countryCode] = []
        }
        countryServers[countryCode]?.append(attributes)

        // Track which countries belong to which continent
        if let continentCode = attributes["continent_code"] {
            if continentCountries[continentCode] == nil {
                continentCountries[continentCode] = []
            }
            continentCountries[continentCode]?.insert(countryCode)
        }
    }

    func parserDidEndDocument(_ parser: XMLParser) {
        // Parsing complete
    }

    // MARK: - Model Access

    /// Returns whether the server list has been parsed
    func isParsed() -> Bool {
        return parsed
    }

    /// Returns the number of continents in the public server list
    func numberOfContinents() -> Int {
        return continentNames.count
    }

    /// Returns the continent name at the given index
    func continentName(at index: Int) -> String {
        guard index >= 0 && index < modelContinents.count else {
            return ""
        }
        return modelContinents[index]
    }

    /// Returns the number of countries in the continent at the given index
    func numberOfCountries(atContinentIndex index: Int) -> Int {
        guard index >= 0 && index < modelCountries.count else {
            return 0
        }
        return modelCountries[index].count
    }

    /// Returns a dictionary representing a country at the given index path.
    /// Keys: "name" (String), "servers" (Array of server dictionaries)
    func country(at indexPath: IndexPath) -> [String: Any]? {
        let continentIndex = indexPath[0]
        let countryIndex = indexPath[1]
        guard continentIndex >= 0 && continentIndex < modelCountries.count else {
            return nil
        }
        let countries = modelCountries[continentIndex]
        guard countryIndex >= 0 && countryIndex < countries.count else {
            return nil
        }
        return countries[countryIndex]
    }

    // MARK: - Objective-C Compatibility

    /// Objective-C compatible accessor for continent name
    @objc(continentNameAtIndex:)
    func objc_continentName(at index: Int) -> String {
        return continentName(at: index)
    }

    /// Objective-C compatible accessor for number of countries
    @objc(numberOfCountriesAtContinentIndex:)
    func objc_numberOfCountries(atContinentIndex index: Int) -> Int {
        return numberOfCountries(atContinentIndex: index)
    }

    /// Objective-C compatible accessor for country dictionary
    @objc(countryAtIndexPath:)
    func objc_country(at indexPath: IndexPath) -> NSDictionary? {
        return country(at: indexPath) as NSDictionary?
    }
}
