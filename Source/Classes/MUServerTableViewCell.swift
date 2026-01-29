// Copyright 2014 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit

/// Custom table view cell with adjusted layout for server/channel lists.
/// Positions image and text labels with proper indentation support.
@objc(MUServerTableViewCell)
@objcMembers
class MUServerTableViewCell: UITableViewCell {

    // MARK: - Initialization

    @objc(initWithReuseIdentifier:)
    init(reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        separatorInset = .zero

        if let imageView = imageView {
            imageView.frame = CGRect(
                x: 8 + CGFloat(indentationLevel) * indentationWidth,
                y: imageView.frame.minY,
                width: imageView.frame.width,
                height: imageView.frame.height
            )
        }

        if let textLabel = textLabel, let imageView = imageView {
            textLabel.frame = CGRect(
                x: imageView.frame.minX + 40,
                y: textLabel.frame.minY,
                width: frame.width - (imageView.frame.minX + 60),
                height: textLabel.frame.height
            )
        }
    }
}
