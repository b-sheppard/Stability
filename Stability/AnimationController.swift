//
//  AnimationController.swift
//  Stability
//
//  Created by Ben Sheppard on 8/20/19.
//  Copyright © 2019 Orb Mentality. All rights reserved.
//

import Foundation
import UIKit

class AnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    var popStyle: Bool = false
    
    func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.20
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        if popStyle {
            
            animatePop(using: transitionContext)
            return
        }
        
        let fz = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let tz = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        
        let f = transitionContext.finalFrame(for: tz)
        
        let fOff = f.offsetBy(dx: f.width, dy: 55)
        tz.view.frame = fOff
        
        transitionContext.containerView.insertSubview(tz.view, aboveSubview: fz.view)
        
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            animations: {
                tz.view.frame = f
        }, completion: {_ in
            transitionContext.completeTransition(true)
        })
    }
    
    func animatePop(using transitionContext: UIViewControllerContextTransitioning) {
        
        let fz = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let tz = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        
        let f = transitionContext.initialFrame(for: fz)
        let fOffPop = f.offsetBy(dx: f.width, dy: 55)
        
        transitionContext.containerView.insertSubview(tz.view, belowSubview: fz.view)
        
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            animations: {
                fz.view.frame = fOffPop
        }, completion: {_ in
            transitionContext.completeTransition(true)
        })
    }
}
/*
class AnimationController: NSObject {
    enum AnimationType {
        case present
        case dismiss
    }
    let duration: Double
    let type: AnimationType
    
    init(duration: Double, type: AnimationType) {
        self.duration = duration
        self.type = type
    }
}

extension AnimationController: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return TimeInterval(exactly: duration) ?? 0
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: .to),
            let fromVC = transitionContext.viewController(forKey: .from) else {
                transitionContext.completeTransition(false)
                return
        }
        switch type {
        case .present:
            transitionContext.containerView.addSubview(toVC.view)
            presentAnimation(with: transitionContext, viewToAnimate: toVC.view)
        case .dismiss:
            print("ph")
        }
        
    }
    
    func presentAnimation(with transitionContext: UIViewControllerContextTransitioning,
                          viewToAnimate: UIView) {
        viewToAnimate.clipsToBounds = true
        viewToAnimate.transform = CGAffineTransform(translationX: 10, y: 0)
        let duration = transitionDuration(using: transitionContext)
        
        UIView.animate(withDuration: duration,
                       delay: 0,
                       options: .curveEaseInOut, animations: {
                        viewToAnimate.transform = CGAffineTransform(translationX: 10, y: 100)
                        
        }) { _ in
            transitionContext.completeTransition(true)
        }
    }
}
*/
