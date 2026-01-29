// Copyright 2009-2010 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit
import MumbleKit

/// Protocol for handling server certificate trust view controller dismissal.
@objc protocol MUServerCertificateTrustViewControllerProtocol: AnyObject {
    func serverCertificateTrustViewControllerDidDismiss(_ trustView: MUServerCertificateTrustViewController)
}

/// View controller for displaying server certificate chain when iOS
/// doesn't trust the certificate and the user wants to inspect it.
/// Extends MUCertificateViewController with a dismiss button and delegate callback.
@objc(MUServerCertificateTrustViewController)
@objcMembers
class MUServerCertificateTrustViewController: MUCertificateViewController {

    // MARK: - Properties

    weak var delegate: MUServerCertificateTrustViewControllerProtocol?

    // MARK: - View Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let dismissButton = UIBarButtonItem(
            title: NSLocalizedString("Dismiss", comment: ""),
            style: .plain,
            target: self,
            action: #selector(dismissClicked(_:))
        )
        navigationItem.leftBarButtonItem = dismissButton
    }

    // MARK: - Actions

    @objc private func dismissClicked(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        delegate?.serverCertificateTrustViewControllerDidDismiss(self)
    }
}
