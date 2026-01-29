// Copyright 2009-2011 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit

/// In-app notification banner controller.
/// Displays queued notification messages with fade animations.
@objc(MUNotificationController)
@objcMembers
class MUNotificationController: NSObject {

    // MARK: - Singleton

    @objc static let shared = MUNotificationController()

    @objc class func sharedController() -> MUNotificationController {
        return shared
    }

    // MARK: - Private Properties

    private var notificationView: UIView?
    private var notificationQueue: [String] = []
    private var running: Bool = false
    private var keyboardFrame: CGRect = .zero

    // MARK: - Initialization

    private override init() {
        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardDidShow(_:)),
            name: UIResponder.keyboardDidShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardDidHide(_:)),
            name: UIResponder.keyboardDidHideNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Keyboard Handling

    @objc private func keyboardDidShow(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let value = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            keyboardFrame = value.cgRectValue
        }
    }

    @objc private func keyboardDidHide(_ notification: Notification) {
        keyboardFrame = .zero
    }

    // MARK: - Public API

    /// Add a notification message to the queue.
    @objc func addNotification(_ text: String) {
        guard notificationQueue.count < 10 else { return }
        notificationQueue.append(text)

        if !running {
            showNext()
        }
    }

    // MARK: - Private Methods

    private func showNext() {
        running = true

        let bounds = UIScreen.main.bounds
        let width = ceil(bounds.size.width - 50.0)
        let height: CGFloat = 50.0

        let frame = CGRect(
            x: 25.0,
            y: ceil((bounds.size.height - keyboardFrame.size.height) / 2) - 25.0,
            width: width,
            height: height
        )

        let container = UIView(frame: frame)
        container.alpha = 0.0
        container.isUserInteractionEnabled = false

        let bg = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        bg.layer.cornerRadius = 8.0
        bg.backgroundColor = .black
        bg.alpha = 0.8
        container.addSubview(bg)

        let lbl = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: height))
        lbl.font = UIFont.systemFont(ofSize: 16.0)
        lbl.text = notificationQueue.removeFirst()
        lbl.textColor = .white
        lbl.backgroundColor = .clear
        lbl.textAlignment = .center
        container.addSubview(lbl)

        // Find the key window
        if let keyWindow = Self.keyWindow() {
            keyWindow.addSubview(container)
        }

        notificationView = container

        UIView.animate(withDuration: 0.1, animations: {
            self.notificationView?.alpha = 1.0
        }, completion: { _ in
            let timer = Timer(timeInterval: 0.3, target: self, selector: #selector(self.hideCurrent), userInfo: nil, repeats: false)
            RunLoop.main.add(timer, forMode: .common)
        })
    }

    @objc private func hideCurrent() {
        UIView.animate(withDuration: 0.1, animations: {
            self.notificationView?.alpha = 0.0
        }, completion: { _ in
            self.notificationView?.removeFromSuperview()
            self.notificationView = nil

            if !self.notificationQueue.isEmpty {
                DispatchQueue.main.async {
                    self.showNext()
                }
            } else {
                self.running = false
            }
        })
    }

    // MARK: - Helpers

    private static func keyWindow() -> UIWindow? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.keyWindow
        }
    }
}
