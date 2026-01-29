// Copyright 2009-2011 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit

/// Notification posted when a connection is opened
let MUConnectionOpenedNotification = "MUConnectionOpenedNotification"

/// Notification posted when a connection is closed
let MUConnectionClosedNotification = "MUConnectionClosedNotification"

/// Manages the connection lifecycle to Mumble servers.
/// Singleton controller that handles connection establishment, authentication,
/// certificate trust, and connection rejection scenarios.
@objc(MUConnectionController)
@objcMembers
class MUConnectionController: UIView, MKConnectionDelegate, MKServerModelDelegate, MUServerCertificateTrustViewControllerProtocol {

    // MARK: - Singleton

    private static var sharedInstance: MUConnectionController?

    @objc static func shared() -> MUConnectionController {
        if sharedInstance == nil {
            sharedInstance = MUConnectionController()
        }
        return sharedInstance!
    }

    // MARK: - Private Properties

    private var connection: MKConnection?
    private var serverModel: MKServerModel?
    private var serverRoot: MUServerRootViewController?
    private weak var parentViewController: UIViewController?
    private var alertCtrl: UIAlertController?
    private var timer: Timer?
    private var numDots: Int = 0

    private var rejectAlertCtrl: UIAlertController?
    private var rejectReason: MKRejectReason = MKRejectReasonNone

    private var hostname: String?
    private var port: UInt = 0
    private var username: String?
    private var password: String?

    private var transitioningDelegate: Any?

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTransitioningDelegate()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTransitioningDelegate()
    }

    private convenience init() {
        self.init(frame: .zero)
    }

    private func setupTransitioningDelegate() {
        if #available(iOS 7.0, *) {
            transitioningDelegate = MUHorizontalFlipTransitionDelegate()
        }
    }

    // MARK: - Public Methods

    @objc(connetToHostname:port:withUsername:andPassword:withParentViewController:)
    func connet(
        toHostname hostName: String?,
        port: UInt,
        withUsername userName: String?,
        andPassword password: String?,
        withParentViewController parentViewController: UIViewController?
    ) {
        self.hostname = hostName
        self.port = port
        self.username = userName
        self.password = password
        self.parentViewController = parentViewController

        showConnectingView()
        establishConnection()
    }

    @objc func isConnected() -> Bool {
        return connection != nil
    }

    @objc func disconnectFromServer() {
        serverRoot?.dismiss(animated: true)
        teardownConnection()
    }

    // MARK: - Connection Management

    private func showConnectingView() {
        let title = "\(NSLocalizedString("Connecting", comment: ""))..."
        let msg = String(
            format: NSLocalizedString("Connecting to %@:%lu", comment: "Connecting to hostname:port"),
            hostname ?? "", port
        )

        alertCtrl = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alertCtrl?.addAction(UIAlertAction(
            title: NSLocalizedString("Cancel", comment: ""),
            style: .cancel
        ) { [weak self] _ in
            self?.teardownConnection()
        })
        parentViewController?.present(alertCtrl!, animated: true)

        timer = Timer.scheduledTimer(
            timeInterval: 0.2,
            target: self,
            selector: #selector(updateTitle),
            userInfo: nil,
            repeats: true
        )
    }

    private func hideConnectingView() {
        hideConnectingView(completion: nil)
    }

    private func hideConnectingView(completion: (() -> Void)?) {
        timer?.invalidate()
        timer = nil

        if alertCtrl != nil {
            parentViewController?.dismiss(animated: true, completion: completion)
            alertCtrl = nil
        } else {
            completion?()
        }
    }

    private func establishConnection() {
        connection = MKConnection()
        connection?.setDelegate(self)
        connection?.setForceTCP(UserDefaults.standard.bool(forKey: "NetworkForceTCP"))

        serverModel = MKServerModel(connection: connection)
        serverModel?.addDelegate(self)

        serverRoot = MUServerRootViewController(connection: connection!, andServerModel: serverModel!)

        // Set the connection's client cert if one is set in the app's preferences
        if let certPersistentId = UserDefaults.standard.object(forKey: "DefaultCertificate") as? Data {
            if let certChain = MUCertificateChainBuilder.buildChain(fromPersistentRef: certPersistentId) {
                connection?.setCertificateChain(certChain)
            }
        }

        connection?.connect(toHost: hostname, port: port)

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name(MUConnectionOpenedNotification), object: nil)
        }
    }

    private func teardownConnection() {
        serverModel?.removeDelegate(self)
        serverModel = nil
        connection?.setDelegate(nil)
        connection?.disconnect()
        connection = nil
        timer?.invalidate()
        serverRoot = nil

        // Reset app badge. The connection is no more.
        UIApplication.shared.applicationIconBadgeNumber = 0

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name(MUConnectionClosedNotification), object: nil)
        }
    }

    @objc private func updateTitle() {
        numDots += 1
        if numDots > 3 {
            numDots = 0
        }

        var dots = "   "
        switch numDots {
        case 1: dots = ".  "
        case 2: dots = ".. "
        case 3: dots = "..."
        default: dots = "   "
        }

        alertCtrl?.title = "\(NSLocalizedString("Connecting", comment: ""))\(dots)"
    }

    // MARK: - MKConnectionDelegate

    func connectionOpened(_ conn: MKConnection) {
        let tokens = MUDatabase.accessTokensForServer(withHostname: conn.hostname(), port: Int(conn.port())) as? [String]
        conn.authenticate(withUsername: username, password: password, accessTokens: tokens)
    }

    func connection(_ conn: MKConnection, closedWithError err: Error?) {
        hideConnectingView()
        if let error = err {
            let alertCtrl = UIAlertController(
                title: NSLocalizedString("Connection closed", comment: ""),
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            alertCtrl.addAction(UIAlertAction(
                title: NSLocalizedString("OK", comment: ""),
                style: .cancel
            ))
            parentViewController?.present(alertCtrl, animated: true)
            teardownConnection()
        }
    }

    func connection(_ conn: MKConnection, unableToConnectWithError err: Error) {
        hideConnectingView()

        var msg = err.localizedDescription

        // errSSLClosedAbort: "connection closed via error".
        // This is the error we get when users hit a global ban on the server.
        let nsError = err as NSError
        if nsError.domain == NSOSStatusErrorDomain && nsError.code == -9806 {
            msg = NSLocalizedString(
                "The TLS connection was closed due to an error.\n\n" +
                "The server might be temporarily rejecting your connection because you have " +
                "attempted to connect too many times in a row.",
                comment: ""
            )
        }

        let alertCtrl = UIAlertController(
            title: NSLocalizedString("Unable to connect", comment: ""),
            message: msg,
            preferredStyle: .alert
        )
        alertCtrl.addAction(UIAlertAction(
            title: NSLocalizedString("OK", comment: ""),
            style: .cancel
        ))
        parentViewController?.present(alertCtrl, animated: true)
        teardownConnection()
    }

    func connection(_ conn: MKConnection, trustFailureInCertificateChain chain: [Any]) {
        // Check the database whether the user trusts the leaf certificate of this server.
        let storedDigest = MUDatabase.digestForServer(withHostname: conn.hostname(), port: Int(conn.port()))
        let cert = conn.peerCertificates()?.first as? MKCertificate
        let serverDigest = cert?.hexDigest()

        let cancelHandler: (UIAlertAction) -> Void = { [weak self] _ in
            self?.teardownConnection()
        }
        let ignoreHandler: (UIAlertAction) -> Void = { [weak self] _ in
            self?.connection?.setIgnoreSSLVerification(true)
            self?.connection?.reconnect()
            self?.showConnectingView()
        }
        let trustHandler: (UIAlertAction) -> Void = { [weak self] _ in
            guard let self = self else { return }
            if let cert = self.connection?.peerCertificates()?.first as? MKCertificate,
               let digest = cert.hexDigest(),
               let hostname = self.connection?.hostname() {
                MUDatabase.storeDigest(digest, forServerWithHostname: hostname, port: Int(self.connection?.port() ?? 0))
            }
            self.connection?.setIgnoreSSLVerification(true)
            self.connection?.reconnect()
            self.showConnectingView()
        }
        let showCertsHandler: (UIAlertAction) -> Void = { [weak self] _ in
            guard let self = self else { return }
            if let certs = self.connection?.peerCertificates() as? [MKCertificate] {
                let certTrustView = MUServerCertificateTrustViewController(certificates: certs)
                certTrustView.delegate = self
                let navCtrl = UINavigationController(rootViewController: certTrustView)
                self.parentViewController?.present(navCtrl, animated: true)
            }
        }

        if let storedDigest = storedDigest {
            if storedDigest == serverDigest {
                // Match
                conn.setIgnoreSSLVerification(true)
                conn.reconnect()
                return
            } else {
                // Mismatch - server is using a new certificate
                hideConnectingView()

                let title = NSLocalizedString("Certificate Mismatch", comment: "")
                let msg = NSLocalizedString("The server presented a different certificate than the one stored for this server", comment: "")

                let alertCtrl = UIAlertController(title: title, message: msg, preferredStyle: .alert)
                alertCtrl.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: cancelHandler))
                alertCtrl.addAction(UIAlertAction(title: NSLocalizedString("Ignore", comment: ""), style: .default, handler: ignoreHandler))
                alertCtrl.addAction(UIAlertAction(title: NSLocalizedString("Trust New Certificate", comment: ""), style: .default, handler: trustHandler))
                alertCtrl.addAction(UIAlertAction(title: NSLocalizedString("Show Certificates", comment: ""), style: .default, handler: showCertsHandler))

                parentViewController?.present(alertCtrl, animated: true)
            }
        } else {
            // No cert hash in database for this hostname-port combo
            hideConnectingView()

            let title = NSLocalizedString("Unable to validate server certificate", comment: "")
            let msg = NSLocalizedString("Mumble was unable to validate the certificate chain of the server.", comment: "")

            let alertCtrl = UIAlertController(title: title, message: msg, preferredStyle: .alert)
            alertCtrl.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: cancelHandler))
            alertCtrl.addAction(UIAlertAction(title: NSLocalizedString("Ignore", comment: ""), style: .default, handler: ignoreHandler))
            alertCtrl.addAction(UIAlertAction(title: NSLocalizedString("Trust Certificate", comment: ""), style: .default, handler: trustHandler))
            alertCtrl.addAction(UIAlertAction(title: NSLocalizedString("Show Certificates", comment: ""), style: .default, handler: showCertsHandler))

            parentViewController?.present(alertCtrl, animated: true)
        }
    }

    func connection(_ conn: MKConnection!, rejectedWith reason: MKRejectReason, explanation: String!) {
        hideConnectingView()
        teardownConnection()

        let title = NSLocalizedString("Connection Rejected", comment: "")
        var msg: String?
        var alertCtrl: UIAlertController?

        let cancelHandler: (UIAlertAction) -> Void = { [weak self] _ in
            guard let self = self else { return }
            if self.rejectReason == MKRejectReasonInvalidUsername || self.rejectReason == MKRejectReasonUsernameInUse {
                self.username = self.rejectAlertCtrl?.textFields?.first?.text
            } else if self.rejectReason == MKRejectReasonWrongServerPassword || self.rejectReason == MKRejectReasonWrongUserPassword {
                self.password = self.rejectAlertCtrl?.textFields?.first?.text
            }
        }
        let reconnectHandler: (UIAlertAction) -> Void = { [weak self] _ in
            guard let self = self else { return }
            if self.rejectReason == MKRejectReasonInvalidUsername || self.rejectReason == MKRejectReasonUsernameInUse {
                self.username = self.rejectAlertCtrl?.textFields?.first?.text
            } else if self.rejectReason == MKRejectReasonWrongServerPassword || self.rejectReason == MKRejectReasonWrongUserPassword {
                self.password = self.rejectAlertCtrl?.textFields?.first?.text
            }
            self.establishConnection()
            self.showConnectingView()
        }
        let usernameConfigHandler: (UITextField) -> Void = { [weak self] textField in
            textField.text = self?.username
        }
        let passwordConfigHandler: (UITextField) -> Void = { [weak self] textField in
            textField.isSecureTextEntry = true
            textField.text = self?.password
        }

        switch reason {
        case MKRejectReasonNone:
            msg = NSLocalizedString("No reason", comment: "")
            alertCtrl = UIAlertController(title: title, message: msg, preferredStyle: .alert)
            alertCtrl?.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel, handler: cancelHandler))

        case MKRejectReasonWrongVersion:
            msg = "Client/server version mismatch"
            alertCtrl = UIAlertController(title: title, message: msg, preferredStyle: .alert)
            alertCtrl?.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel, handler: cancelHandler))

        case MKRejectReasonInvalidUsername:
            msg = NSLocalizedString("Invalid username", comment: "")
            alertCtrl = UIAlertController(title: title, message: msg, preferredStyle: .alert)
            alertCtrl?.addTextField(configurationHandler: usernameConfigHandler)
            alertCtrl?.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: cancelHandler))
            alertCtrl?.addAction(UIAlertAction(title: NSLocalizedString("Reconnect", comment: ""), style: .default, handler: reconnectHandler))

        case MKRejectReasonWrongUserPassword:
            msg = NSLocalizedString("Wrong certificate or password for existing user", comment: "")
            alertCtrl = UIAlertController(title: title, message: msg, preferredStyle: .alert)
            alertCtrl?.addTextField(configurationHandler: passwordConfigHandler)
            alertCtrl?.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: cancelHandler))
            alertCtrl?.addAction(UIAlertAction(title: NSLocalizedString("Reconnect", comment: ""), style: .default, handler: reconnectHandler))

        case MKRejectReasonWrongServerPassword:
            msg = NSLocalizedString("Wrong server password", comment: "")
            alertCtrl = UIAlertController(title: title, message: msg, preferredStyle: .alert)
            alertCtrl?.addTextField(configurationHandler: passwordConfigHandler)
            alertCtrl?.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: cancelHandler))
            alertCtrl?.addAction(UIAlertAction(title: NSLocalizedString("Reconnect", comment: ""), style: .default, handler: reconnectHandler))

        case MKRejectReasonUsernameInUse:
            msg = NSLocalizedString("Username already in use", comment: "")
            alertCtrl = UIAlertController(title: title, message: msg, preferredStyle: .alert)
            alertCtrl?.addTextField(configurationHandler: usernameConfigHandler)
            alertCtrl?.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: cancelHandler))
            alertCtrl?.addAction(UIAlertAction(title: NSLocalizedString("Reconnect", comment: ""), style: .default, handler: reconnectHandler))

        case MKRejectReasonServerIsFull:
            msg = NSLocalizedString("Server is full", comment: "")
            alertCtrl = UIAlertController(title: title, message: msg, preferredStyle: .alert)
            alertCtrl?.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel, handler: cancelHandler))

        case MKRejectReasonNoCertificate:
            msg = NSLocalizedString("A certificate is needed to connect to this server", comment: "")
            alertCtrl = UIAlertController(title: title, message: msg, preferredStyle: .alert)
            alertCtrl?.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel, handler: cancelHandler))

        default:
            msg = NSLocalizedString("Unknown rejection reason", comment: "")
            alertCtrl = UIAlertController(title: title, message: msg, preferredStyle: .alert)
            alertCtrl?.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel, handler: cancelHandler))
        }

        rejectAlertCtrl = alertCtrl
        rejectReason = reason

        if let alertCtrl = alertCtrl {
            parentViewController?.present(alertCtrl, animated: true)
        }
    }

    // MARK: - MKServerModelDelegate

    func serverModel(_ model: MKServerModel, joinedServerAs user: MKUser) {
        MUDatabase.storeUsername(user.userName(), forServerWithHostname: model.hostname(), port: model.port())

        hideConnectingView { [weak self] in
            guard let self = self else { return }
            self.serverRoot?.takeOwnershipOfConnectionDelegate()

            self.username = nil
            self.hostname = nil
            self.password = nil

            self.serverRoot?.modalPresentationStyle = .fullScreen
            self.parentViewController?.navigationController?.present(self.serverRoot!, animated: true)
            self.parentViewController = nil
        }
    }

    // MARK: - MUServerCertificateTrustViewControllerProtocol

    func serverCertificateTrustViewControllerDidDismiss(_ trustView: MUServerCertificateTrustViewController) {
        showConnectingView()
        connection?.reconnect()
    }
}
