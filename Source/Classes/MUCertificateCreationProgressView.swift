// Copyright 2009-2010 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit

/// Progress view displayed during certificate generation.
/// Loaded from MUCertificateCreationProgressView storyboard.
@objc(MUCertificateCreationProgressView)
@objcMembers
class MUCertificateCreationProgressView: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet private weak var backgroundImage: UIImageView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var emailLabel: UILabel!
    @IBOutlet private weak var pleaseWaitLabel: UILabel!

    // MARK: - Private Properties

    private var identityName: String?
    private var emailAddress: String?

    // MARK: - Class Methods

    @objc(progressViewWithName:email:)
    static func progressView(withName name: String?, email: String?) -> MUCertificateCreationProgressView {
        let sb = UIStoryboard(name: "MUCertificateCreationProgressView", bundle: nil)
        guard let vc = sb.instantiateInitialViewController() as? MUCertificateCreationProgressView else {
            fatalError("Failed to load MUCertificateCreationProgressView from storyboard")
        }
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

        // Set background color for iOS 7+
        backgroundImage.backgroundColor = MUColor.backgroundViewiOS7()

        // Remove text shadows for iOS 7+
        nameLabel.shadowOffset = .zero
        emailLabel.shadowOffset = .zero
        pleaseWaitLabel.shadowOffset = .zero
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
