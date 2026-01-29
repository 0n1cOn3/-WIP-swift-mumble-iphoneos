// Copyright 2009-2011 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit
@preconcurrency import WebKit

/// View controller for displaying legal information.
/// Loads Legal.html from the app bundle in a WKWebView.
@objc(MULegalViewController)
@objcMembers
class MULegalViewController: UIViewController, WKNavigationDelegate {

    // MARK: - Properties

    private var webView: WKWebView!

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create WKWebView programmatically
        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.navigationDelegate = self
        webView.backgroundColor = .black
        view.addSubview(webView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.title = NSLocalizedString("Legal", comment: "")

        let done = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneButtonClicked(_:))
        )
        navigationItem.rightBarButtonItem = done

        if let path = Bundle.main.path(forResource: "Legal", ofType: "html"),
           let html = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            webView.load(
                html,
                mimeType: "text/html",
                characterEncodingName: "utf-8",
                baseURL: URL(string: "http://localhost")!
            )
        }
    }

    // MARK: - Actions

    @objc private func doneButtonClicked(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated,
           let url = navigationAction.request.url,
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
}
