// Copyright 2009-2010 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit

/// Custom table view cell for displaying certificate information.
@objc(MUCertificateCell)
@objcMembers
class MUCertificateCell: UITableViewCell {

    // MARK: - Constants

    static let reuseIdentifier = "CertificateCell"
    static let cellHeight: CGFloat = 84

    // MARK: - UI Elements

    private var certImage: UIImageView!
    private var nameLabel: UILabel!
    private var emailLabel: UILabel!
    private var issuerLabel: UILabel!
    private var expiryLabel: UILabel!

    // MARK: - Private Properties

    private var _isCurrentCert: Bool = false
    private var _isExpired: Bool = false
    private var _isIntermediate: Bool = false

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        // Certificate image (64x64)
        certImage = UIImageView()
        certImage.contentMode = .scaleAspectFit
        certImage.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(certImage)

        // Name label (bold)
        nameLabel = UILabel()
        nameLabel.font = UIFont.boldSystemFont(ofSize: 17)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)

        // Email label
        emailLabel = UILabel()
        emailLabel.font = UIFont.systemFont(ofSize: 14)
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(emailLabel)

        // Issuer label
        issuerLabel = UILabel()
        issuerLabel.font = UIFont.systemFont(ofSize: 14)
        issuerLabel.textColor = .gray
        issuerLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(issuerLabel)

        // Expiry label
        expiryLabel = UILabel()
        expiryLabel.font = UIFont.systemFont(ofSize: 14)
        expiryLabel.textColor = .gray
        expiryLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(expiryLabel)

        // Layout constraints
        NSLayoutConstraint.activate([
            certImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 9),
            certImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            certImage.widthAnchor.constraint(equalToConstant: 64),
            certImage.heightAnchor.constraint(equalToConstant: 64),

            nameLabel.leadingAnchor.constraint(equalTo: certImage.trailingAnchor, constant: 13),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),

            emailLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            emailLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),

            issuerLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            issuerLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            issuerLabel.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 2),

            expiryLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            expiryLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            expiryLabel.topAnchor.constraint(equalTo: issuerLabel.bottomAnchor, constant: 2),
        ])

        // Default image
        certImage.image = UIImage(named: "certificatecell")
    }

    // MARK: - Class Methods

    @objc
    static func createCell() -> MUCertificateCell {
        return MUCertificateCell(style: .default, reuseIdentifier: reuseIdentifier)
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
