// Copyright 2009-2011 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit
import MumbleKit

/// Factory class for creating accessory views showing user state icons.
/// Displays icons for authenticated, muted, deafened, suppressed, etc.
@objc(MUUserStateAcessoryView)
@objcMembers
class MUUserStateAcessoryView: NSObject {

    // MARK: - Class Methods

    @objc(viewForUser:)
    static func view(forUser user: MKUser) -> UIView {
        let iconHeight: CGFloat = 24.0
        let iconWidth: CGFloat = 28.0

        var states: [String] = []

        if user.isAuthenticated() {
            states.append("authenticated")
        }
        if user.isSelfDeafened() {
            states.append("deafened_self")
        }
        if user.isSelfMuted() {
            states.append("muted_self")
        }
        if user.isMuted() {
            states.append("muted_server")
        }
        if user.isDeafened() {
            states.append("deafened_server")
        }
        if user.isLocalMuted() {
            states.append("muted_local")
        }
        if user.isSuppressed() {
            states.append("muted_suppressed")
        }
        if user.isPrioritySpeaker() {
            states.append("priorityspeaker")
        }

        var widthOffset = CGFloat(states.count) * iconWidth
        let stateView = UIView(frame: CGRect(x: 0, y: 0, width: widthOffset, height: iconHeight))

        for imageName in states {
            guard let img = UIImage(named: imageName) else { continue }

            let imgView = UIImageView(image: img)
            let ypos = (iconHeight - img.size.height) / 2.0
            let xpos = (iconWidth - img.size.width) / 2.0
            widthOffset -= iconWidth - xpos
            imgView.frame = CGRect(
                x: ceil(widthOffset),
                y: ceil(ypos),
                width: img.size.width,
                height: img.size.height
            )
            stateView.addSubview(imgView)
        }

        return stateView
    }
}
