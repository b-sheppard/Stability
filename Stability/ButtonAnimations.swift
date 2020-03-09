//
//  ButtonAnimations.swift
//  Stability
//
//  Created by Ben Sheppard on 3/6/20.
//  Copyright © 2020 Orb Mentality. All rights reserved.
//

import Foundation
import UIKit

extension UIButton {
    @objc func shrinkButton() {
      UIView.animate(withDuration: 0.05,
      animations: {
          self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
      })
    }
    @objc func growButton() {
      UIView.animate(withDuration: 0.05,
      animations: {
          self.transform = CGAffineTransform(scaleX: 1, y: 1)
      })
    }

    func shrinkGrowButton() {
      UIView.animate(withDuration: 0.2,
      animations: {
          self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
      }, completion: { _ in
          UIView.animate(withDuration: 0.2) {
              self.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
          }
      })
    }
}

extension UITextField {
    func shrinkGrowButton() {
      UIView.animate(withDuration: 0.2,
      animations: {
          self.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
      }, completion: { _ in
          UIView.animate(withDuration: 0.2) {
              self.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
          }
      })
    }
}
