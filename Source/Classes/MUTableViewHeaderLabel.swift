// Copyright 2009-2011 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit

/// Styled label used for table view section headers.
/// Displays white centered text on a clear background.
@objc(MUTableViewHeaderLabel)
@objcMembers
class MUTableViewHeaderLabel: UILabel {

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    convenience init() {
        self.init(frame: .zero)
    }

    private func configure() {
        font = UIFont.boldSystemFont(ofSize: 18.0)
        textColor = .white
        backgroundColor = .clear
        textAlignment = .center
    }

    // MARK: - Class Methods

    @objc(defaultHeaderHeight)
    static func defaultHeaderHeight() -> CGFloat {
        return 44.0
    }

    @objc(labelWithText:)
    static func label(withText text: String?) -> MUTableViewHeaderLabel {
        let label = MUTableViewHeaderLabel()
        label.text = text
        return label
    }
}
