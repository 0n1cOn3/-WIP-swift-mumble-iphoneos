// Copyright 2009-2010 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit

/// Discovers and displays Mumble servers on the local network using Bonjour/mDNS.
/// Supports connecting to discovered servers and adding them as favourites.
@objc(MULanServerListController)
@objcMembers
class MULanServerListController: UITableViewController, NetServiceBrowserDelegate, NetServiceDelegate {

    // MARK: - Private Properties

    private var browser: NetServiceBrowser
    private var netServices: [NetService] = []

    // MARK: - Initialization

    override init(style: UITableView.Style) {
        browser = NetServiceBrowser()
        super.init(style: style)
        browser.delegate = self
        browser.schedule(in: .main, forMode: .default)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        browser = NetServiceBrowser()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        browser.delegate = self
        browser.schedule(in: .main, forMode: .default)
    }

    required init?(coder: NSCoder) {
        browser = NetServiceBrowser()
        super.init(coder: coder)
        browser.delegate = self
        browser.schedule(in: .main, forMode: .default)
    }

    @objc convenience init() {
        self.init(style: .plain)
    }

    // MARK: - View Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.title = NSLocalizedString("LAN Servers", comment: "")

        if #available(iOS 7.0, *) {
            tableView.separatorStyle = .singleLine
            tableView.separatorInset = .zero
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        browser.searchForServices(ofType: "_mumble._tcp", inDomain: "local.")
    }

    // MARK: - NetServiceBrowserDelegate

    func netServiceBrowser(
        _ browser: NetServiceBrowser,
        didFind service: NetService,
        moreComing: Bool
    ) {
        netServices.append(service)
        netServices.sort { ($0.name) < ($1.name) }

        if let newIndex = netServices.firstIndex(of: service) {
            let indexPath = IndexPath(row: newIndex, section: 0)
            tableView.insertRows(at: [indexPath], with: .fade)
        }

        service.schedule(in: .main, forMode: .default)
        service.delegate = self
        service.resolve(withTimeout: 10.0)
    }

    func netServiceBrowser(
        _ browser: NetServiceBrowser,
        didRemove service: NetService,
        moreComing: Bool
    ) {
        if let index = netServices.firstIndex(of: service) {
            netServices.remove(at: index)
            let indexPath = IndexPath(row: index, section: 0)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        service.remove(from: .main, forMode: .default)
    }

    // MARK: - NetServiceDelegate

    func netServiceDidResolveAddress(_ sender: NetService) {
        if let index = netServices.firstIndex(of: sender), index >= 0 {
            let indexPath = IndexPath(row: index, section: 0)
            tableView.reloadRows(at: [indexPath], with: .fade)
        }
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return netServices.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let netService = netServices[indexPath.row]
        var cell = tableView.dequeueReusableCell(withIdentifier: MUServerCell.reuseIdentifier()) as? MUServerCell
        if cell == nil {
            cell = MUServerCell()
        }
        cell?.populate(
            fromDisplayName: netService.name,
            hostName: netService.hostName,
            port: "\(netService.port)"
        )
        cell?.selectionStyle = .gray
        return cell!
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let netService = netServices[indexPath.row]

        // Server not yet resolved
        guard netService.hostName != nil else {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }

        let sheetCtrl = UIAlertController(
            title: netService.name,
            message: nil,
            preferredStyle: .actionSheet
        )

        sheetCtrl.addAction(UIAlertAction(
            title: NSLocalizedString("Cancel", comment: ""),
            style: .cancel
        ) { [weak self] _ in
            self?.tableView.deselectRow(at: indexPath, animated: true)
        })

        sheetCtrl.addAction(UIAlertAction(
            title: NSLocalizedString("Add as favourite", comment: ""),
            style: .default
        ) { [weak self] _ in
            self?.presentAddAsFavouriteDialog(for: netService)
        })

        sheetCtrl.addAction(UIAlertAction(
            title: NSLocalizedString("Connect", comment: ""),
            style: .default
        ) { [weak self] _ in
            self?.promptForUsernameAndConnect(to: netService, at: indexPath)
        })

        present(sheetCtrl, animated: true)
    }

    // MARK: - Connection

    private func promptForUsernameAndConnect(to netService: NetService, at indexPath: IndexPath) {
        let title = NSLocalizedString("Username", comment: "")
        let msg = NSLocalizedString("Please enter the username you wish to use on this server", comment: "")

        let alertCtrl = UIAlertController(title: title, message: msg, preferredStyle: .alert)

        alertCtrl.addTextField { textField in
            if let hostName = netService.hostName {
                textField.text = MUDatabase.usernameForServer(withHostname: hostName, port: netService.port)
            }
        }

        alertCtrl.addAction(UIAlertAction(
            title: NSLocalizedString("Cancel", comment: ""),
            style: .cancel
        ) { [weak self] _ in
            self?.tableView.deselectRow(at: indexPath, animated: true)
        })

        alertCtrl.addAction(UIAlertAction(
            title: NSLocalizedString("Connect", comment: ""),
            style: .default
        ) { [weak self] _ in
            guard let self = self else { return }
            let username = alertCtrl.textFields?.first?.text
            let connCtrlr = MUConnectionController.shared()
            connCtrlr?.connet(
                toHostname: netService.hostName,
                port: UInt(netService.port),
                withUsername: username,
                andPassword: nil,
                withParentViewController: self
            )
            self.tableView.deselectRow(at: indexPath, animated: true)
        })

        present(alertCtrl, animated: true)
    }

    // MARK: - Add as Favourite

    private func presentAddAsFavouriteDialog(for netService: NetService) {
        let favServ = MUFavouriteServer()
        favServ.displayName = netService.name
        favServ.hostName = netService.hostName
        favServ.port = UInt(netService.port)
        if let hostName = netService.hostName {
            favServ.userName = MUDatabase.username(forServerWithHostname: hostName, port: UInt(netService.port))
        }

        let modalNav = UINavigationController()
        let editView = MUFavouriteServerEditViewController(inEditMode: false, withContentOf: favServ)

        editView.setTarget(self)
        editView.setDoneAction(#selector(doneButtonClicked(_:)))
        modalNav.pushViewController(editView, animated: false)

        navigationController?.present(modalNav, animated: true)
    }

    @objc private func doneButtonClicked(_ sender: Any) {
        guard let editView = sender as? MUFavouriteServerEditViewController else { return }
        guard let favServ = editView.copyFavouriteFromContent() else { return }

        MUDatabase.storeFavourite(favServ)

        let favController = MUFavouriteServerListController()
        navigationController?.popToRootViewController(animated: false)
        navigationController?.pushViewController(favController, animated: true)
    }
}
