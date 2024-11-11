//
//  PresentingAnimator.swift
//  TelegramUIKit
//
//  Created by surexnx on 09.11.2024.
//

import UIKit

class PresentingAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    private let originFrame: CGRect
    private let duration: TimeInterval = 0.5

    init(originFrame: CGRect = CGRect(origin: CGPoint.zero, size: CGSize.zero)) {
        self.originFrame = originFrame

        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: .to) as? UIPreviewController,
              let toView = toVC.view else {
            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView
        containerView.addSubview(toView)
        toView.isHidden = true

        let view = toVC.copyPreview()
        containerView.addSubview(view)
        view.frame = originFrame

        let finalFrame = transitionContext.finalFrame(for: toVC)

        UIView.animate(withDuration: duration, animations: {
            view.frame.size.width = 300
            view.frame.size.height = 400
            view.center = CGPoint(x: finalFrame.midX, y: finalFrame.midY)

        }, completion: { _ in
            toView.isHidden = false
            toView.frame = finalFrame
            view.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
