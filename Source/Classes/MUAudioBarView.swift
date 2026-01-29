// Copyright 2009-2011 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit

/// Visual audio level indicator that displays voice activity detection thresholds.
/// Shows a tri-color bar (red/yellow/green) with the current audio level overlaid.
@objc(MUAudioBarView)
@objcMembers
class MUAudioBarView: UIView {

    // MARK: - Private Properties

    private var below: CGFloat = 0.0
    private var above: CGFloat = 0.0
    private var minValue: CGFloat = 0.0
    private var maxValue: CGFloat = 1.0
    private var currentValue: CGFloat = 0.5
    private var timer: Timer?

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTimer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTimer()
    }

    deinit {
        timer?.invalidate()
    }

    private func setupTimer() {
        let newTimer = Timer(timeInterval: 1.0/60.0, target: self, selector: #selector(tickTock), userInfo: nil, repeats: true)
        timer = newTimer
        RunLoop.main.add(newTimer, forMode: .common)
    }

    // MARK: - Public Methods

    func setBelow(_ value: CGFloat) {
        below = value
    }

    func setAbove(_ value: CGFloat) {
        above = value
    }

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        let bounds = self.bounds
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.clear(bounds)

        // Read current thresholds from user defaults
        below = CGFloat(UserDefaults.standard.float(forKey: "AudioVADBelow"))
        above = CGFloat(UserDefaults.standard.float(forKey: "AudioVADAbove"))

        let scale = bounds.width / (maxValue - minValue)
        let belowX = Int((below - minValue) * scale)
        let aboveX = Int((above - minValue) * scale)
        let valueX = Int((currentValue - minValue) * scale)

        // Colors with alpha (background) and opaque (foreground)
        let redA = MUColor.badPing().withAlphaComponent(0.6).cgColor
        let redO = MUColor.badPing().cgColor
        let yellowA = MUColor.mediumPing().withAlphaComponent(0.6).cgColor
        let yellowO = MUColor.mediumPing().cgColor
        let greenA = MUColor.goodPing().withAlphaComponent(0.6).cgColor
        let greenO = MUColor.goodPing().cgColor

        // Invalid configuration - fill with red
        if above < below {
            ctx.setFillColor(redA)
            ctx.fill(bounds)
            return
        }

        // Draw background zones
        let redBounds = CGRect(x: bounds.origin.x, y: 0, width: CGFloat(belowX), height: bounds.height)
        ctx.setFillColor(redA)
        ctx.fill(redBounds)

        var x = redBounds.width
        let yellowBounds = CGRect(x: x, y: 0, width: CGFloat(aboveX) - x, height: bounds.height)
        ctx.setFillColor(yellowA)
        ctx.fill(yellowBounds)

        x = yellowBounds.origin.x + yellowBounds.width
        var greenBounds = CGRect(x: x, y: 0, width: bounds.width - x, height: bounds.height)
        ctx.setFillColor(greenA)
        ctx.fill(greenBounds)

        // Draw foreground (current value)
        if valueX > belowX {
            ctx.setFillColor(redO)
            ctx.fill(redBounds)
        } else {
            let partialRed = CGRect(x: bounds.origin.x, y: 0, width: CGFloat(valueX), height: bounds.height)
            ctx.setFillColor(redO)
            ctx.fill(partialRed)
        }

        if valueX > aboveX {
            ctx.setFillColor(yellowO)
            ctx.fill(yellowBounds)

            greenBounds = CGRect(x: x, y: 0, width: CGFloat(valueX) - x, height: bounds.height)
            ctx.setFillColor(greenO)
            ctx.fill(greenBounds)
        } else if valueX > belowX && valueX <= aboveX {
            x = redBounds.width
            let partialYellow = CGRect(x: x, y: 0, width: CGFloat(valueX) - x, height: bounds.height)
            ctx.setFillColor(yellowO)
            ctx.fill(partialYellow)
        }
    }

    // MARK: - Timer

    @objc private func tickTock() {
        let captureManager = MUAudioCaptureManager.shared
        var kind = UserDefaults.standard.string(forKey: "AudioVADKind") ?? "amplitude"

        if !UserDefaults.standard.bool(forKey: "AudioPreprocessor") {
            kind = "amplitude"
        }

        if kind == "snr" {
            currentValue = CGFloat(captureManager.speechProbability)
        } else {
            currentValue = CGFloat(captureManager.meterLevel)
        }

        setNeedsDisplay()
    }
}
