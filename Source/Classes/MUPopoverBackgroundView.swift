// Copyright 2009-2012 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit

/// Custom popover background view for iPad.
/// Uses a black arrow-up background image.
@objc(MUPopoverBackgroundView)
@objcMembers
class MUPopoverBackgroundView: UIPopoverBackgroundView {

    // MARK: - Private Properties

    private var imgView: UIImageView?

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)

        let insets = UIEdgeInsets(top: 41.0, left: 47.0, bottom: 10.0, right: 10.0)
        if let img = UIImage(named: "_UIPopoverViewBlackBackgroundArrowUp") {
            let stretchableImg = img.resizableImage(withCapInsets: insets)
            imgView = UIImageView(image: stretchableImg)
            addSubview(imgView!)
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - UIPopoverBackgroundView Overrides

    override var arrowDirection: UIPopoverArrowDirection {
        get { return .up }
        set { }
    }

    override var arrowOffset: CGFloat {
        get { return 0.0 }
        set { }
    }

    override class func arrowBase() -> CGFloat {
        return 35.0
    }

    override class func arrowHeight() -> CGFloat {
        return 19.0
    }

    override class func contentViewInsets() -> UIEdgeInsets {
        return UIEdgeInsets(top: 8.0, left: 11.0, bottom: 11.0, right: 11.0)
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        imgView?.frame = frame
    }
}
