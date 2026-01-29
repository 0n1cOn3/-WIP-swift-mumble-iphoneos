// Copyright 2014 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit

/// Custom view controller transition delegate that performs a horizontal flip animation.
@objc(MUHorizontalFlipTransitionDelegate)
@objcMembers
class MUHorizontalFlipTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning {

    // MARK: - UIViewControllerTransitioningDelegate

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }

    // MARK: - UIViewControllerAnimatedTransitioning

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.7
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        guard let fromViewController = transitionContext.viewController(forKey: .from),
              let toViewController = transitionContext.viewController(forKey: .to) else {
            return
        }

        containerView.addSubview(fromViewController.view)
        containerView.addSubview(toViewController.view)

        let animationOption: UIView.AnimationOptions
        if toViewController.presentedViewController === fromViewController {
            animationOption = .transitionFlipFromLeft
        } else {
            animationOption = .transitionFlipFromRight
        }

        UIView.transition(
            from: fromViewController.view,
            to: toViewController.view,
            duration: transitionDuration(using: transitionContext),
            options: animationOption
        ) { _ in
            transitionContext.completeTransition(true)
        }
    }
}
