// Copyright 2009-2010 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit
import Security

/// Certificate preferences controller for viewing, selecting, and managing
/// client certificates stored in the Keychain.
@objc(MUCertificatePreferencesViewController)
@objcMembers
class MUCertificatePreferencesViewController: UITableViewController {

    // MARK: - Private Properties

    private var certificateItems: [[String: Any]] = []
    private var selectedIndex: Int = 0
    private var showAll: Bool = false

    // MARK: - Initialization

    init() {
        super.init(style: .plain)
        preferredContentSize = CGSize(width: 320, height: 480)
        showAll = UserDefaults.standard.bool(forKey: "CertificatesShowIntermediates")
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - View Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.title = NSLocalizedString("Certificates", comment: "")

        tableView.separatorStyle = .singleLine
        tableView.separatorInset = .zero
        // Set tint for disclosure indicator
        tableView.tintColor = UIColor(red: 0xc7/255.0, green: 0xc7/255.0, blue: 0xcc/255.0, alpha: 1.0)

        fetchCertificates()
        tableView.reloadData()

        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonClicked(_:))
        )
        navigationItem.rightBarButtonItem = addButton
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return certificateItems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = MUCertificateCell.load(fromStoryboard: ()) else {
            return UITableViewCell()
        }

        let dict = certificateItems[indexPath.row]
        guard let cert = dict["cert"] as? MKCertificate else {
            return cell
        }

        cell.setSubjectName(cert.subjectName())
        cell.setEmail(cert.emailAddress())
        cell.setIssuerText(cert.issuerName())

        if cert.isValid(on: Date()) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let formattedDate = dateFormatter.string(from: cert.notAfter())
            let fmt = NSLocalizedString("Expires on %@", comment: "Certificate expiry explanation")
            cell.setExpiryText(String(format: fmt, formattedDate))
        } else {
            cell.setExpiryText(NSLocalizedString("Expired", comment: "Date is past the certificate's notAfter date"))
            cell.setIsExpired(true)
        }

        let persistentRef = dict["persistentRef"] as? Data
        let curPersistentRef = UserDefaults.standard.data(forKey: "DefaultCertificate")

        if let isIdentity = dict["isIdentity"] as? Bool, isIdentity {
            cell.setIsIntermediate(false)
            cell.selectionStyle = .gray
        } else {
            cell.setIsIntermediate(true)
            cell.selectionStyle = .none
        }

        if let persistentRef = persistentRef, persistentRef == curPersistentRef {
            selectedIndex = indexPath.row
            cell.setIsCurrentCertificate(true)
        } else {
            cell.setIsCurrentCertificate(false)
        }

        cell.accessoryType = .detailButton

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85.0
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let dict = certificateItems[indexPath.row]

        // Don't allow selection of intermediates
        guard let isIdentity = dict["isIdentity"] as? Bool, isIdentity else {
            return
        }

        guard let persistentRef = dict["persistentRef"] as? Data else {
            return
        }

        UserDefaults.standard.set(persistentRef, forKey: "DefaultCertificate")

        if let prevCell = tableView.cellForRow(at: IndexPath(row: selectedIndex, section: 0)) as? MUCertificateCell {
            prevCell.setIsCurrentCertificate(false)
        }
        if let curCell = tableView.cellForRow(at: indexPath) as? MUCertificateCell {
            curCell.setIsCurrentCertificate(true)
        }
        selectedIndex = indexPath.row

        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteCertificate(forRow: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .right)
        }
    }

    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let dict = certificateItems[indexPath.row]
        guard let persistentRef = dict["persistentRef"] as? Data else {
            return
        }
        let certView = MUCertificateViewController(persistentRef: persistentRef)
        navigationController?.pushViewController(certView, animated: true)
    }

    // MARK: - Actions

    @objc private func addButtonClicked(_ addButton: UIBarButtonItem) {
        let showAllCerts = NSLocalizedString("Show All Certificates", comment: "")
        let showIdentities = NSLocalizedString("Show Identities Only", comment: "")

        let sheetCtrl = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        sheetCtrl.addAction(UIAlertAction(
            title: NSLocalizedString("Cancel", comment: ""),
            style: .cancel,
            handler: nil
        ))

        sheetCtrl.addAction(UIAlertAction(
            title: NSLocalizedString("Generate New Certificate", comment: ""),
            style: .default,
            handler: { [weak self] _ in
                let navCtrl = UINavigationController()
                navCtrl.modalPresentationStyle = .currentContext
                let certGen = MUCertificateCreationView()
                navCtrl.pushViewController(certGen, animated: false)
                self?.navigationController?.present(navCtrl, animated: true, completion: nil)
            }
        ))

        sheetCtrl.addAction(UIAlertAction(
            title: showAll ? showIdentities : showAllCerts,
            style: .default,
            handler: { [weak self] _ in
                guard let self = self else { return }
                self.showAll = !self.showAll
                UserDefaults.standard.set(self.showAll, forKey: "CertificatesShowIntermediates")
                self.fetchCertificates()
                self.tableView.reloadData()
            }
        ))

        sheetCtrl.addAction(UIAlertAction(
            title: NSLocalizedString("Import From iTunes", comment: ""),
            style: .default,
            handler: { [weak self] _ in
                let diskImportViewController = MUCertificateDiskImportViewController()
                let navController = UINavigationController(rootViewController: diskImportViewController)
                self?.navigationController?.present(navController, animated: true, completion: nil)
            }
        ))

        present(sheetCtrl, animated: true, completion: nil)
    }

    // MARK: - Private Methods

    private func fetchCertificates() {
        guard let persistentRefs = MUCertificateController.persistentRefs(forIdentities: ()) as? [Data] else {
            certificateItems = []
            return
        }

        certificateItems = []

        for persistentRef in persistentRefs {
            if let cert = MUCertificateController.certificate(withPersistentRef: persistentRef) {
                certificateItems.append([
                    "cert": cert,
                    "persistentRef": persistentRef,
                    "isIdentity": true
                ])
            }
        }

        if showAll {
            // Extract hashes of identity certs
            var identityCertHashes: [Data] = []
            for item in certificateItems {
                if let cert = item["cert"] as? MKCertificate {
                    identityCertHashes.append(cert.digest())
                }
            }

            // Query for all certificates
            let query: [String: Any] = [
                kSecClass as String: kSecClassCertificate,
                kSecReturnPersistentRef as String: true,
                kSecMatchLimit as String: kSecMatchLimitAll
            ]

            var result: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &result)

            if status == errSecSuccess, let refs = result as? [Data] {
                for ref in refs {
                    let certQuery: [String: Any] = [
                        kSecValuePersistentRef as String: ref,
                        kSecReturnRef as String: true,
                        kSecMatchLimit as String: kSecMatchLimitOne
                    ]

                    var certResult: CFTypeRef?
                    if SecItemCopyMatching(certQuery as CFDictionary, &certResult) == errSecSuccess,
                       let secCert = certResult {
                        let secCertRef = secCert as! SecCertificate
                        let certData = SecCertificateCopyData(secCertRef) as Data

                        if let consideredCert = MKCertificate(certificate: certData, privateKey: nil) {
                            let consideredDigest = consideredCert.digest()

                            let alreadyPresent = identityCertHashes.contains { $0 == consideredDigest }

                            if !alreadyPresent {
                                certificateItems.append([
                                    "cert": consideredCert,
                                    "persistentRef": ref,
                                    "isIdentity": false
                                ])
                            }
                        }
                    }
                }
            }
        }
    }

    private func deleteCertificate(forRow row: Int) {
        let dict = certificateItems[row]
        guard let persistentRef = dict["persistentRef"] as? Data else {
            return
        }

        let err = MUCertificateController.deleteCertificate(withPersistentRef: persistentRef)
        if err == noErr {
            certificateItems.remove(at: row)
        }
    }
}
