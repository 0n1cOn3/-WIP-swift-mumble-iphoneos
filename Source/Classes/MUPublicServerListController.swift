// Copyright 2009-2010 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit

/// Displays the Mumble public server directory, organized by continent and country.
/// Parses server list XML asynchronously and presents a grouped table view.
@objc(MUPublicServerListController)
@objcMembers
class MUPublicServerListController: UITableViewController {

    // MARK: - Private Properties

    private var serverList: MUPublicServerList

    // MARK: - Initialization

    override init(style: UITableView.Style) {
        serverList = MUPublicServerList()
        super.init(style: style)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        serverList = MUPublicServerList()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        serverList = MUPublicServerList()
        super.init(coder: coder)
    }

    @objc convenience init() {
        self.init(style: .grouped)
    }

    // MARK: - View Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.title = NSLocalizedString("Public Servers", comment: "")

        tableView.backgroundView = MUBackgroundView.backgroundView()

        if #available(iOS 7.0, *) {
            tableView.separatorStyle = .singleLine
            tableView.separatorInset = .zero
        } else {
            tableView.separatorStyle = .none
        }

        if !serverList.isParsed() {
            let activityIndicator = UIActivityIndicatorView(style: .white)
            let barIndicator = UIBarButtonItem(customView: activityIndicator)
            navigationItem.rightBarButtonItem = barIndicator
            activityIndicator.startAnimating()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        DispatchQueue.global(qos: .default).async { [weak self] in
            guard let self = self else { return }

            if self.serverList.isParsed() {
                DispatchQueue.main.async {
                    self.navigationItem.rightBarButtonItem = nil
                }
                return
            }

            self.serverList.parse()

            DispatchQueue.main.async {
                self.navigationItem.rightBarButtonItem = nil
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return serverList.numberOfContinents()
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let continentName = serverList.continentName(at: section)
        return MUTableViewHeaderLabel.label(withText: continentName)
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return MUTableViewHeaderLabel.defaultHeaderHeight()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return serverList.numberOfCountries(atContinentIndex: section)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "countryItem"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
        }

        cell?.accessoryType = .disclosureIndicator

        if let countryInfo = serverList.country(at: indexPath) {
            cell?.textLabel?.text = countryInfo["name"] as? String

            if let servers = countryInfo["servers"] as? [[String: String]] {
                let numServers = servers.count
                let serverWord = numServers > 1 ? "servers" : "server"
                cell?.detailTextLabel?.text = "\(numServers) \(serverWord)"
            }
        }

        cell?.selectionStyle = .default
        return cell!
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let countryInfo = serverList.country(at: indexPath) else { return }
        guard let countryName = countryInfo["name"] as? String else { return }
        guard let countryServers = countryInfo["servers"] as? [[String: Any]] else { return }

        let countryController = MUCountryServerListController(
            name: countryName,
            serverList: countryServers
        )
        navigationController?.pushViewController(countryController, animated: true)
    }
}
