// Copyright 2009-2010 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit

/// Displays and manages the user's list of favourite (saved) servers.
/// Supports adding, editing, deleting, and connecting to servers.
@objc(MUFavouriteServerListController)
@objcMembers
class MUFavouriteServerListController: UITableViewController {

    // MARK: - Private Properties

    private var favouriteServers: [MUFavouriteServer] = []
    private var editMode: Bool = false
    private var editedServer: MUFavouriteServer?

    // MARK: - Initialization

    override init(style: UITableView.Style) {
        super.init(style: style)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    @objc convenience init() {
        self.init(style: .plain)
    }

    deinit {
        MUDatabase.storeFavourites(favouriteServers)
    }

    // MARK: - View Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.title = NSLocalizedString("Favourite Servers", comment: "")

        if #available(iOS 7.0, *) {
            tableView.separatorStyle = .singleLine
            tableView.separatorInset = .zero
        }

        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonClicked(_:))
        )
        navigationItem.rightBarButtonItem = addButton

        reloadFavourites()
    }

    // MARK: - Data Loading

    private func reloadFavourites() {
        if let servers = MUDatabase.fetchAllFavourites() as? [MUFavouriteServer] {
            favouriteServers = servers.sorted { $0.compare($1) == .orderedAscending }
        } else {
            favouriteServers = []
        }
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favouriteServers.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let favServ = favouriteServers[indexPath.row]
        var cell = tableView.dequeueReusableCell(withIdentifier: MUServerCell.reuseIdentifier()) as? MUServerCell
        if cell == nil {
            cell = MUServerCell()
        }
        cell?.populate(from: favServ)
        cell?.selectionStyle = .gray
        return cell!
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        if editingStyle == .delete {
            deleteFavourite(at: indexPath)
        }
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let favServ = favouriteServers[indexPath.row]
        let isPad = UIDevice.current.userInterfaceIdiom == .pad

        let sheetTitle = isPad ? nil : favServ.displayName

        let sheetCtrl = UIAlertController(
            title: sheetTitle,
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
            title: NSLocalizedString("Delete", comment: ""),
            style: .destructive
        ) { [weak self] _ in
            self?.confirmDeleteFavourite(at: indexPath)
        })

        sheetCtrl.addAction(UIAlertAction(
            title: NSLocalizedString("Edit", comment: ""),
            style: .default
        ) { [weak self] _ in
            self?.presentEditDialog(for: favServ)
            self?.tableView.deselectRow(at: indexPath, animated: true)
        })

        sheetCtrl.addAction(UIAlertAction(
            title: NSLocalizedString("Connect", comment: ""),
            style: .default
        ) { [weak self] _ in
            self?.connectToServer(favServ)
            self?.tableView.deselectRow(at: indexPath, animated: true)
        })

        present(sheetCtrl, animated: true)
    }

    // MARK: - Delete Confirmation

    private func confirmDeleteFavourite(at indexPath: IndexPath) {
        let title = NSLocalizedString("Delete Favourite", comment: "")
        let msg = NSLocalizedString("Are you sure you want to delete this favourite server?", comment: "")

        let alertCtrl = UIAlertController(title: title, message: msg, preferredStyle: .alert)

        alertCtrl.addAction(UIAlertAction(
            title: NSLocalizedString("No", comment: ""),
            style: .cancel
        ))

        alertCtrl.addAction(UIAlertAction(
            title: NSLocalizedString("Yes", comment: ""),
            style: .default
        ) { [weak self] _ in
            self?.deleteFavourite(at: indexPath)
        })

        present(alertCtrl, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    private func deleteFavourite(at indexPath: IndexPath) {
        let favServ = favouriteServers[indexPath.row]
        MUDatabase.deleteFavourite(favServ)

        favouriteServers.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - Connection

    private func connectToServer(_ favServ: MUFavouriteServer) {
        var userName = favServ.userName
        if userName == nil {
            userName = UserDefaults.standard.string(forKey: "DefaultUserName")
        }

        let connCtrlr = MUConnectionController.shared()
        connCtrlr.connet(
            toHostname: favServ.hostName,
            port: favServ.port,
            withUsername: userName,
            andPassword: favServ.password,
            withParentViewController: self
        )
    }

    // MARK: - Modal Edit Dialogs

    @objc func presentNewFavouriteDialog() {
        let modalNav = UINavigationController()
        let editView = MUFavouriteServerEditViewController(inEditMode: false, withContentOfFavouriteServer: nil)

        editMode = false
        editedServer = nil

        editView.setTarget(self)
        editView.setDoneAction(#selector(doneButtonClicked(_:)))
        modalNav.pushViewController(editView, animated: false)

        modalNav.modalPresentationStyle = .formSheet
        navigationController?.present(modalNav, animated: true)
    }

    @objc func presentEditDialog(for favServ: MUFavouriteServer) {
        let modalNav = UINavigationController()
        let editView = MUFavouriteServerEditViewController(inEditMode: true, withContentOfFavouriteServer: favServ)

        editMode = true
        editedServer = favServ

        editView.setTarget(self)
        editView.setDoneAction(#selector(doneButtonClicked(_:)))
        modalNav.pushViewController(editView, animated: false)

        modalNav.modalPresentationStyle = .formSheet
        navigationController?.present(modalNav, animated: true)
    }

    // MARK: - Actions

    @objc private func addButtonClicked(_ sender: Any) {
        presentNewFavouriteDialog()
    }

    @objc private func doneButtonClicked(_ sender: Any) {
        guard let editView = sender as? MUFavouriteServerEditViewController else { return }
        let newServer = editView.copyFavouriteFromContent()

        MUDatabase.storeFavourite(newServer)

        reloadFavourites()
        tableView.reloadData()
    }
}
