// Copyright 2014 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit

/// Factory class for creating standard background views.
/// Returns a solid color view on iOS 7+.
@objc(MUBackgroundView)
@objcMembers
class MUBackgroundView: UIView {

    // MARK: - Class Methods

    @objc(backgroundView)
    static func backgroundView() -> UIView {
        let view = UIView()
        view.backgroundColor = MUColor.backgroundViewiOS7()
        return view
    }
}
