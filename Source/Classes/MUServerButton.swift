// Copyright 2013 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit

/// Custom button displaying server info with ping-based gradient coloring.
@objc(MUServerButton)
@objcMembers
class MUServerButton: UIControl, MKServerPingerDelegate {

    // MARK: - Private Properties

    private var displayname: String?
    private var hostname: String?
    private var port: String?
    private var username: String?

    private var pinger: MKServerPinger?
    private var pingMs: UInt = 0
    private var userCount: UInt = 0
    private var maxUserCount: UInt = 0

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        clearsContextBeforeDrawing = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isOpaque = false
        clearsContextBeforeDrawing = true
    }

    // MARK: - Highlight State

    override var isHighlighted: Bool {
        didSet {
            setNeedsDisplay()
        }
    }

    // MARK: - Population

    @objc func populate(fromDisplayName displayName: String?, hostName: String?, port: String?) {
        self.displayname = displayName
        self.port = port
        self.pinger = nil

        if let hostName = hostName, !hostName.isEmpty {
            self.hostname = hostName
            pinger = MKServerPinger(hostname: hostName, port: port)
            pinger?.setDelegate(self)
        } else {
            self.hostname = NSLocalizedString("(No Server)", comment: "")
        }

        setNeedsDisplay()
    }

    @objc func populate(from favServ: MUFavouriteServer) {
        displayname = favServ.displayName
        hostname = favServ.hostName
        port = "\(favServ.port)"

        if let userName = favServ.userName, !userName.isEmpty {
            username = userName
        } else {
            username = UserDefaults.standard.string(forKey: "DefaultUserName")
        }

        pinger = nil
        if let hostname = hostname, !hostname.isEmpty {
            pinger = MKServerPinger(hostname: hostname, port: port)
            pinger?.setDelegate(self)
        } else {
            self.hostname = NSLocalizedString("(No Server)", comment: "")
        }

        setNeedsDisplay()
    }

    // MARK: - MKServerPingerDelegate

    func serverPingerResult(_ result: UnsafeMutablePointer<MKServerPingerResult>!) {
        guard let result = result?.pointee else { return }
        pingMs = UInt(result.ping * 1000.0)
        userCount = UInt(result.cur_users)
        maxUserCount = UInt(result.max_users)
        setNeedsDisplay()
    }

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        // Color Declarations
        let greenStart = UIColor(red: 0.376, green: 0.604, blue: 0.294, alpha: 1)
        let greenStop = UIColor(red: 0.238, green: 0.383, blue: 0.186, alpha: 1)
        let redStart = UIColor(red: 0.82, green: 0.302, blue: 0.329, alpha: 1)
        let redStop = UIColor(red: 0.498, green: 0.16, blue: 0.178, alpha: 1)
        let yellowStart = UIColor(red: 0.949, green: 0.871, blue: 0.412, alpha: 1)
        let yellowStop = UIColor(red: 0.715, green: 0.652, blue: 0.284, alpha: 1)
        let highlightStart = UIColor(red: 0.618, green: 0.598, blue: 0.598, alpha: 1)
        let highlightStop = UIColor(red: 0.389, green: 0.368, blue: 0.368, alpha: 1)
        let blackShadowColor = UIColor.black

        // Gradient colors based on state
        let gradientColors: [CGColor]
        if isHighlighted {
            gradientColors = [highlightStart.cgColor, highlightStop.cgColor]
        } else if pingMs <= 125 {
            gradientColors = [greenStart.cgColor, greenStop.cgColor]
        } else if pingMs > 125 && pingMs <= 250 {
            gradientColors = [yellowStart.cgColor, yellowStop.cgColor]
        } else {
            gradientColors = [redStart.cgColor, redStop.cgColor]
        }

        let gradientLocations: [CGFloat] = [0, 1]
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors as CFArray, locations: gradientLocations) else { return }

        // Shadow Declarations
        let shadow2Offset = CGSize(width: 0.1, height: 1.1)
        let shadow2BlurRadius: CGFloat = 2
        let textShadowOffset = CGSize(width: 0.1, height: 1.1)
        let textShadowBlurRadius: CGFloat = 1

        // Frame
        let frame = CGRect(x: 0, y: 0, width: 232, height: 143)

        // Text content
        let titleTextContent = displayname ?? ""
        let pingTextContent = pingMs < 999 ? "\(pingMs) ms" : "∞ ms"
        let userTextContent = "\(userCount)/\(maxUserCount) ppl"

        let usernameTextContent: String
        let addressTextContent: String?
        if username == nil {
            usernameTextContent = "\(hostname ?? ""):\(port ?? "")"
            addressTextContent = nil
        } else {
            usernameTextContent = username ?? ""
            addressTextContent = "\(hostname ?? ""):\(port ?? "")"
        }

        // Rounded Rectangle Drawing
        let roundedRectangleRect = CGRect(
            x: frame.minX + 2.5,
            y: frame.minY + 1.5,
            width: frame.width - 5,
            height: frame.height - 5
        )
        let roundedRectanglePath = UIBezierPath(roundedRect: roundedRectangleRect, cornerRadius: 16)

        context.saveGState()
        context.setShadow(offset: shadow2Offset, blur: shadow2BlurRadius, color: blackShadowColor.cgColor)
        context.beginTransparencyLayer(auxiliaryInfo: nil)
        roundedRectanglePath.addClip()
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: roundedRectangleRect.midX, y: roundedRectangleRect.minY),
            end: CGPoint(x: roundedRectangleRect.midX, y: roundedRectangleRect.maxY),
            options: []
        )
        context.endTransparencyLayer()
        context.restoreGState()

        UIColor.clear.setStroke()
        roundedRectanglePath.lineWidth = 1
        roundedRectanglePath.stroke()

        // Title Text Drawing
        let titleTextRect = CGRect(x: frame.minX + 2, y: frame.minY + 11, width: frame.width - 4, height: frame.height - 95)
        context.saveGState()
        context.setShadow(offset: textShadowOffset, blur: textShadowBlurRadius, color: blackShadowColor.cgColor)
        UIColor.white.setFill()
        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.lineBreakMode = .byWordWrapping
        titleParagraphStyle.alignment = .center
        titleTextContent.draw(in: titleTextRect, withAttributes: [
            .font: UIFont.systemFont(ofSize: 32),
            .paragraphStyle: titleParagraphStyle
        ])
        context.restoreGState()

        // Ping Text Drawing
        let pingTextRect = CGRect(x: frame.minX + 18, y: frame.minY + 103, width: 108, height: 27)
        context.saveGState()
        context.setShadow(offset: textShadowOffset, blur: textShadowBlurRadius, color: blackShadowColor.cgColor)
        UIColor.white.setFill()
        let pingParagraphStyle = NSMutableParagraphStyle()
        pingParagraphStyle.lineBreakMode = .byWordWrapping
        pingParagraphStyle.alignment = .left
        pingTextContent.draw(in: pingTextRect, withAttributes: [
            .font: UIFont.systemFont(ofSize: UIFont.buttonFontSize),
            .paragraphStyle: pingParagraphStyle
        ])
        context.restoreGState()

        // User Text Drawing
        let userTextRect = CGRect(
            x: frame.minX + 127,
            y: frame.minY + 103,
            width: floor((frame.width - 127) * 0.85714 + 0.5),
            height: 27
        )
        context.saveGState()
        context.setShadow(offset: textShadowOffset, blur: textShadowBlurRadius, color: blackShadowColor.cgColor)
        UIColor.white.setFill()
        let userParagraphStyle = NSMutableParagraphStyle()
        userParagraphStyle.lineBreakMode = .byWordWrapping
        userParagraphStyle.alignment = .right
        userTextContent.draw(in: userTextRect, withAttributes: [
            .font: UIFont.systemFont(ofSize: UIFont.buttonFontSize),
            .paragraphStyle: userParagraphStyle
        ])
        context.restoreGState()

        // Address Text Drawing
        if let addressTextContent = addressTextContent {
            let addressTextRect = CGRect(x: frame.minX + 2, y: frame.minY + 65, width: frame.width - 5, height: frame.height - 126)
            context.saveGState()
            context.setShadow(offset: textShadowOffset, blur: textShadowBlurRadius, color: blackShadowColor.cgColor)
            UIColor.white.setFill()
            let addressParagraphStyle = NSMutableParagraphStyle()
            addressParagraphStyle.lineBreakMode = .byWordWrapping
            addressParagraphStyle.alignment = .center
            addressTextContent.draw(in: addressTextRect, withAttributes: [
                .font: UIFont.systemFont(ofSize: UIFont.buttonFontSize),
                .paragraphStyle: addressParagraphStyle
            ])
            context.restoreGState()
        }

        // Username Text Drawing
        let usernameTextRect = CGRect(x: frame.minX + 2, y: frame.minY + 49, width: frame.width - 5, height: frame.height - 126)
        context.saveGState()
        context.setShadow(offset: textShadowOffset, blur: textShadowBlurRadius, color: blackShadowColor.cgColor)
        UIColor.white.setFill()
        let usernameParagraphStyle = NSMutableParagraphStyle()
        usernameParagraphStyle.lineBreakMode = .byWordWrapping
        usernameParagraphStyle.alignment = .center
        usernameTextContent.draw(in: usernameTextRect, withAttributes: [
            .font: UIFont.systemFont(ofSize: 13),
            .paragraphStyle: usernameParagraphStyle
        ])
        context.restoreGState()
    }
}
