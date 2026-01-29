// Copyright 2009-2010 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit

/// Welcome screen for iPhone devices.
/// Displays the Mumble logo and server list options.
@objc(MUWelcomeScreenPhone)
@objcMembers
class MUWelcomeScreenPhone: UITableViewController {

    // MARK: - Initialization

    init() {
        super.init(style: .grouped)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - View Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.title = "Mumble"
        navigationController?.isToolbarHidden = true

        tableView.backgroundView = MUBackgroundView.backgroundView()
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = .zero
        tableView.isScrollEnabled = false

        let about = UIBarButtonItem(
            title: NSLocalizedString("About", comment: ""),
            style: .plain,
            target: self,
            action: #selector(aboutClicked(_:))
        )
        navigationItem.rightBarButtonItem = about

        let prefs = UIBarButtonItem(
            title: NSLocalizedString("Preferences", comment: ""),
            style: .plain,
            target: self,
            action: #selector(prefsClicked(_:))
        )
        navigationItem.leftBarButtonItem = prefs
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let img = MUImage.image(named: "WelcomeScreenIcon") else { return nil }
        let imgView = UIImageView(image: img)
        imgView.contentMode = .center
        imgView.frame = CGRect(x: 0, y: 0, width: img.size.width, height: img.size.height)
        return imgView
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let img = MUImage.image(named: "WelcomeScreenIcon") else { return 0 }
        return img.size.height
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "welcomeItem")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "welcomeItem")
        }

        guard let cell = cell else { return UITableViewCell() }

        cell.selectionStyle = .default

        switch indexPath.row {
        case 0:
            cell.textLabel?.text = NSLocalizedString("Public Servers", comment: "")
        case 1:
            cell.textLabel?.text = NSLocalizedString("Favourite Servers", comment: "")
        case 2:
            cell.textLabel?.text = NSLocalizedString("LAN Servers", comment: "")
        default:
            break
        }

        cell.textLabel?.isHidden = false

        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            let serverList = MUPublicServerListController()
            navigationController?.pushViewController(serverList, animated: true)
        case 1:
            let favList = MUFavouriteServerListController()
            navigationController?.pushViewController(favList, animated: true)
        case 2:
            let lanList = MULanServerListController()
            navigationController?.pushViewController(lanList, animated: true)
        default:
            break
        }
    }

    // MARK: - Actions

    @objc private func aboutClicked(_ sender: Any) {
        #if MUMBLE_BETA_DIST
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        let revision = Bundle.main.object(forInfoDictionaryKey: "MumbleGitRevision") as? String ?? ""
        let aboutTitle = "Mumble \(version) (\(revision))"
        #else
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        let aboutTitle = "Mumble \(version)"
        #endif

        let aboutMessage = NSLocalizedString("Low latency, high quality voice chat", comment: "")

        let aboutAlert = UIAlertController(title: aboutTitle, message: aboutMessage, preferredStyle: .alert)

        aboutAlert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel, handler: nil))

        aboutAlert.addAction(UIAlertAction(title: NSLocalizedString("Website", comment: ""), style: .default) { _ in
            if let url = URL(string: "https://www.mumble.info/") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        })

        aboutAlert.addAction(UIAlertAction(title: NSLocalizedString("Legal", comment: ""), style: .default) { [weak self] _ in
            let legalView = MULegalViewController()
            let navController = UINavigationController(rootViewController: legalView)
            self?.navigationController?.present(navController, animated: true, completion: nil)
        })

        aboutAlert.addAction(UIAlertAction(title: NSLocalizedString("Support", comment: ""), style: .default) { _ in
            if let url = URL(string: "https://github.com/mumble-voip/mumble-iphoneos/issues") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        })

        present(aboutAlert, animated: true, completion: nil)
    }

    @objc private func prefsClicked(_ sender: Any) {
        let prefs = MUPreferencesViewController()
        navigationController?.pushViewController(prefs, animated: true)
    }
}
