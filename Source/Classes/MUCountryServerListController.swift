// Copyright 2009-2010 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit

/// Displays servers within a specific country from the public server list.
/// Supports search filtering, connecting to servers, and adding as favourites.
@objc(MUCountryServerListController)
@objcMembers
class MUCountryServerListController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {

    // MARK: - Private Properties

    private var tableViewInstance: UITableView!
    private var visibleServers: [[String: Any]] = []
    private var countryServers: [[String: Any]] = []
    private var countryName: String = ""

    // MARK: - Initialization

    @objc(initWithName:serverList:)
    init(name: String, serverList: [[String: Any]]) {
        super.init(nibName: nil, bundle: nil)
        countryServers = serverList
        visibleServers = serverList
        countryName = name
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Properties

    @objc var tableView: UITableView {
        return tableViewInstance
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        tableViewInstance = UITableView(frame: view.bounds, style: .plain)
        tableViewInstance.dataSource = self
        tableViewInstance.delegate = self
        tableViewInstance.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        view.addSubview(tableViewInstance)

        resetSearch()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.titleView = nil
        navigationItem.title = countryName
        navigationItem.hidesBackButton = false

        if #available(iOS 7.0, *) {
            tableViewInstance.separatorStyle = .singleLine
            tableViewInstance.separatorInset = .zero
        }

        let searchButton = UIBarButtonItem(
            barButtonSystemItem: .search,
            target: self,
            action: #selector(searchButtonClicked(_:))
        )
        navigationItem.rightBarButtonItem = searchButton

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visibleServers.count
    }

    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        let serverItem = visibleServers[indexPath.row]
        if let ca = serverItem["ca"] as? Int, ca > 0 {
            cell.backgroundColor = MUColor.verifiedCertificateChainColor()
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: MUServerCell.reuseIdentifier()) as? MUServerCell
        if cell == nil {
            cell = MUServerCell()
        }

        let serverItem = visibleServers[indexPath.row]
        cell?.populate(
            fromDisplayName: serverItem["name"] as? String,
            hostName: serverItem["ip"] as? String,
            port: serverItem["port"] as? String
        )
        cell?.selectionStyle = .gray
        return cell!
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let serverItem = visibleServers[indexPath.row]

        let serverName = serverItem["name"] as? String ?? ""
        let sheetCtrl = UIAlertController(
            title: serverName,
            message: nil,
            preferredStyle: .actionSheet
        )

        sheetCtrl.addAction(UIAlertAction(
            title: NSLocalizedString("Cancel", comment: ""),
            style: .cancel
        ) { _ in
            tableView.deselectRow(at: indexPath, animated: true)
        })

        sheetCtrl.addAction(UIAlertAction(
            title: NSLocalizedString("Add as favourite", comment: ""),
            style: .default
        ) { [weak self] _ in
            self?.presentAddAsFavouriteDialog(for: serverItem)
        })

        sheetCtrl.addAction(UIAlertAction(
            title: NSLocalizedString("Connect", comment: ""),
            style: .default
        ) { [weak self] _ in
            self?.promptForUsernameAndConnect(to: serverItem)
        })

        present(sheetCtrl, animated: true) { [weak self] in
            self?.tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    // MARK: - Connection

    private func promptForUsernameAndConnect(to serverItem: [String: Any]) {
        let title = NSLocalizedString("Username", comment: "")
        let msg = NSLocalizedString("Please enter the username you wish to use on this server", comment: "")

        let alertCtrl = UIAlertController(title: title, message: msg, preferredStyle: .alert)

        alertCtrl.addTextField { textField in
            let ip = serverItem["ip"] as? String ?? ""
            let port = (serverItem["port"] as? String).flatMap { Int($0) } ?? 0
            textField.text = MUDatabase.username(forServerWithHostname: ip, port: UInt(port))
        }

        alertCtrl.addAction(UIAlertAction(
            title: NSLocalizedString("Cancel", comment: ""),
            style: .cancel
        ))

        alertCtrl.addAction(UIAlertAction(
            title: NSLocalizedString("Connect", comment: ""),
            style: .default
        ) { [weak self] _ in
            guard let self = self else { return }
            let ip = serverItem["ip"] as? String
            let port = (serverItem["port"] as? String).flatMap { UInt($0) } ?? 0
            let username = alertCtrl.textFields?.first?.text

            let connCtrlr = MUConnectionController.shared()
            connCtrlr?.connet(
                toHostname: ip,
                port: port,
                withUsername: username,
                andPassword: nil,
                withParentViewController: self
            )
        })

        present(alertCtrl, animated: true)
    }

    // MARK: - Add as Favourite

    @objc func presentAddAsFavouriteDialog(for serverItem: [String: Any]) {
        let favServ = MUFavouriteServer()
        favServ.displayName = serverItem["name"] as? String
        favServ.hostName = serverItem["ip"] as? String
        if let portStr = serverItem["port"] as? String, let port = UInt(portStr) {
            favServ.port = port
            if let ip = serverItem["ip"] as? String {
                favServ.userName = MUDatabase.username(forServerWithHostname: ip, port: port)
            }
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

    // MARK: - Search

    private func resetSearch() {
        visibleServers = countryServers
    }

    private func performSearch(for term: String) {
        DispatchQueue.global(qos: .default).async { [weak self] in
            guard let self = self else { return }

            let results = self.countryServers.filter { serverItem in
                let name = serverItem["name"] as? String ?? ""
                let ip = serverItem["ip"] as? String ?? ""
                return name.range(of: term, options: .caseInsensitive) != nil ||
                       ip.range(of: term, options: .caseInsensitive) != nil
            }

            DispatchQueue.main.async {
                self.visibleServers = results
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - UISearchBarDelegate

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let searchText = searchBar.text {
            performSearch(for: searchText)
        }
        searchBar.resignFirstResponder()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            resetSearch()
            tableView.reloadData()
            return
        }
        performSearch(for: searchText)
    }

    // MARK: - Keyboard Notifications

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        guard let durationValue = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSValue else { return }
        guard let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSValue else { return }
        guard let frameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        var duration: TimeInterval = 0
        durationValue.getValue(&duration)

        var curve: UIView.AnimationCurve = .easeInOut
        curveValue.getValue(&curve)

        var keyboardFrame = frameValue.cgRectValue
        keyboardFrame = view.convert(keyboardFrame, from: nil)

        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(duration)
        UIView.setAnimationCurve(curve)
        tableViewInstance.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height, right: 0)
        tableViewInstance.scrollIndicatorInsets = tableViewInstance.contentInset
        UIView.commitAnimations()
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        guard let durationValue = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSValue else { return }
        guard let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSValue else { return }

        var duration: TimeInterval = 0
        durationValue.getValue(&duration)

        var curve: UIView.AnimationCurve = .easeInOut
        curveValue.getValue(&curve)

        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(duration)
        UIView.setAnimationCurve(curve)
        tableViewInstance.contentInset = .zero
        tableViewInstance.scrollIndicatorInsets = .zero
        UIView.commitAnimations()
    }

    // MARK: - Actions

    @objc private func searchButtonClicked(_ sender: Any) {
        navigationItem.hidesBackButton = true

        let cancelButton = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelSearchButtonClicked(_:))
        )
        navigationItem.rightBarButtonItem = cancelButton

        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = self
        searchBar.barStyle = .black
        searchBar.sizeToFit()
        navigationItem.titleView = searchBar

        searchBar.becomeFirstResponder()
    }

    @objc private func cancelSearchButtonClicked(_ sender: Any) {
        resetSearch()
        tableView.reloadData()

        let searchButton = UIBarButtonItem(
            barButtonSystemItem: .search,
            target: self,
            action: #selector(searchButtonClicked(_:))
        )
        navigationItem.rightBarButtonItem = searchButton

        navigationItem.hidesBackButton = false
        navigationItem.titleView = nil
        navigationItem.title = countryName
    }
}
