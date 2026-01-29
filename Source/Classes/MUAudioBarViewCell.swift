// Copyright 2009-2011 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit

/// Table view cell containing an audio bar view as its background.
/// Used in voice activity setup to display the current audio level.
@objc(MUAudioBarViewCell)
@objcMembers
class MUAudioBarViewCell: UITableViewCell {

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let audioBarView = MUAudioBarView(frame: bounds)
        audioBarView.setBelow(0.4)
        audioBarView.setAbove(0.6)
        backgroundView = audioBarView

        // No corner rounding on iOS 7+
        backgroundView?.layer.masksToBounds = false
        backgroundView?.layer.cornerRadius = 0.0

        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
