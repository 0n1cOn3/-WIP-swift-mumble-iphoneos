// Copyright 2009-2010 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit

/// Custom table view cell for displaying certificate information.
/// Loaded from MUCertificateCell storyboard.
@objc(MUCertificateCell)
@objcMembers
class MUCertificateCell: UITableViewCell {

    // MARK: - IBOutlets

    @IBOutlet private weak var certImage: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var emailLabel: UILabel!
    @IBOutlet private weak var issuerLabel: UILabel!
    @IBOutlet private weak var expiryLabel: UILabel!

    // MARK: - Private Properties

    private var _isCurrentCert: Bool = false
    private var _isExpired: Bool = false
    private var _isIntermediate: Bool = false

    // MARK: - Class Methods

    @objc
    static func loadFromStoryboard() -> MUCertificateCell? {
        let sb = UIStoryboard(name: "MUCertificateCell", bundle: nil)
        guard let tvc = sb.instantiateInitialViewController() as? UITableViewController else {
            return nil
        }
        tvc.loadViewIfNeeded()
        return tvc.tableView.dequeueReusableCell(withIdentifier: "CertificateCell") as? MUCertificateCell
    }

    // MARK: - Public Methods

    func setSubjectName(_ name: String?) {
        nameLabel.text = name
    }

    func setEmail(_ email: String?) {
        emailLabel.text = email
    }

    func setIssuerText(_ issuerText: String?) {
        issuerLabel.text = issuerText
    }

    func setExpiryText(_ expiryText: String?) {
        expiryLabel.text = expiryText
    }

    func setIsIntermediate(_ isIntermediate: Bool) {
        _isIntermediate = isIntermediate
        if _isIntermediate {
            certImage.image = UIImage(named: "certificatecell-intermediate")
        } else {
            certImage.image = UIImage(named: "certificatecell")
        }
    }

    var isIntermediate: Bool {
        return _isIntermediate
    }

    func setIsExpired(_ isExpired: Bool) {
        _isExpired = isExpired
        expiryLabel.textColor = .red
    }

    var isExpired: Bool {
        return _isExpired
    }

    func setIsCurrentCertificate(_ isCurrent: Bool) {
        _isCurrentCert = isCurrent
        if isCurrent {
            certImage.image = UIImage(named: "certificatecell-selected")
            nameLabel.textColor = MUColor.selectedText()
            emailLabel.textColor = MUColor.selectedText()
        } else {
            if _isIntermediate {
                certImage.image = UIImage(named: "certificatecell-intermediate")
            } else {
                certImage.image = UIImage(named: "certificatecell")
            }
            nameLabel.textColor = .black
            emailLabel.textColor = .black
        }
    }

    var isCurrentCertificate: Bool {
        return _isCurrentCert
    }
}
