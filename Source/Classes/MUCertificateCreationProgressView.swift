// Copyright 2009-2010 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit

/// Progress view displayed during certificate generation.
@objc(MUCertificateCreationProgressView)
@objcMembers
class MUCertificateCreationProgressView: UIViewController {

    // MARK: - UI Elements

    private var backgroundImage: UIImageView!
    private var iconImageView: UIImageView!
    private var activityIndicator: UIActivityIndicatorView!
    private var nameLabel: UILabel!
    private var emailLabel: UILabel!
    private var pleaseWaitLabel: UILabel!

    // MARK: - Private Properties

    private var identityName: String?
    private var emailAddress: String?

    // MARK: - Class Methods

    @objc(progressViewWithName:email:)
    static func progressView(withName name: String?, email: String?) -> MUCertificateCreationProgressView {
        let vc = MUCertificateCreationProgressView()
        vc.identityName = name
        vc.emailAddress = email

        if UIDevice.current.userInterfaceIdiom == .pad {
            _ = vc.view  // Force load view
            vc.view.backgroundColor = .groupTableViewBackground
        }

        return vc
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = MUColor.backgroundViewiOS7()

        // Background image view (full screen)
        backgroundImage = UIImageView(frame: view.bounds)
        backgroundImage.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundImage.contentMode = .scaleToFill
        backgroundImage.backgroundColor = MUColor.backgroundViewiOS7()
        view.addSubview(backgroundImage)

        // Icon image (certificate icon)
        iconImageView = UIImageView(image: UIImage(named: "certificatecreation.png"))
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(iconImageView)

        // Name label
        nameLabel = UILabel()
        nameLabel.font = UIFont.boldSystemFont(ofSize: 17)
        nameLabel.textColor = .white
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameLabel)

        // Email label
        emailLabel = UILabel()
        emailLabel.font = UIFont.boldSystemFont(ofSize: 13)
        emailLabel.textColor = .white
        emailLabel.textAlignment = .center
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emailLabel)

        // Activity indicator
        if #available(iOS 13.0, *) {
            activityIndicator = UIActivityIndicatorView(style: .large)
        } else {
            activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
        }
        activityIndicator.color = .white
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)

        // Please wait label
        pleaseWaitLabel = UILabel()
        pleaseWaitLabel.font = UIFont.boldSystemFont(ofSize: 17)
        pleaseWaitLabel.textColor = .white
        pleaseWaitLabel.textAlignment = .center
        pleaseWaitLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pleaseWaitLabel)

        // Layout constraints
        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            iconImageView.widthAnchor.constraint(equalToConstant: 128),
            iconImageView.heightAnchor.constraint(equalToConstant: 128),

            nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nameLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 30),
            nameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            emailLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            emailLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            emailLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 40),

            pleaseWaitLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pleaseWaitLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 20),
            pleaseWaitLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            pleaseWaitLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.title = NSLocalizedString("Generating Certificate", comment: "Title for certificate generator view controller")
        navigationItem.hidesBackButton = true

        nameLabel.text = identityName

        if let email = emailAddress, !email.isEmpty {
            emailLabel.text = "<\(email)>"
        } else {
            emailLabel.text = nil
        }

        pleaseWaitLabel.text = NSLocalizedString("Please Wait...", comment: "'Please Wait' text for certificate generation")
        activityIndicator.startAnimating()
    }
}
