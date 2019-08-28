//
//  RootPageViewController.swift
//  Stability
//
//  Created by Ben Sheppard on 8/23/19.
//  Copyright © 2019 Orb Mentality. All rights reserved.
//

import Foundation
import UIKit

class RootPageViewController: UIPageViewController, UIPageViewControllerDataSource {
    lazy var viewControllerList:[UIViewController] = {
        let profileViewController = ProfileViewController()
        let homeViewController = HomeViewController()
        let taskViewController = TaskViewController()
        
        return [profileViewController, homeViewController, taskViewController]
    }()
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let vcIndex = viewControllerList.firstIndex(of:viewController) else { return nil }
        let prevIndex = vcIndex - 1
        
        guard prevIndex >= 0 else { return nil }
        
        guard viewControllerList.count > prevIndex else { return nil }
        
        return viewControllerList[prevIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let vcIndex = viewControllerList.firstIndex(of:viewController) else { return nil }
        let nextIndex = vcIndex + 1
        
        guard viewControllerList.count != nextIndex else { return nil }
        
        guard viewControllerList.count > nextIndex else { return nil }
        
        return viewControllerList[nextIndex]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let gray = UIColor(hex:5263695)
        
        self.addHelpButton()
        self.navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.barTintColor = gray
        
        let secondVC = viewControllerList[1]
        self.setViewControllers([secondVC], direction: .forward, animated: true, completion: nil)
        self.dataSource = self
    }
}

extension UIViewController {
    // adds help button at top of each screen
    func addHelpButton() {
        let gray = UIColor(hex:5263695)
        let help = UIButton(frame: CGRect(x:UIScreen.main.bounds.width - 60,
                                          y: 20,
                                          width: 60,
                                          height: 30
        ))
        help.setTitle("Help", for: .normal)
        help.setTitleColor(gray, for: .normal)
        help.addTarget(self, action: #selector(UIViewController.showHelp), for: .touchUpInside)
        
        view.addSubview(help)
    }
    
    @objc func showHelp() {
        print("touched!")
        let helpVC = HelpViewController()
        self.addChild(helpVC)
        self.view.addSubview(helpVC.view)
        helpVC.animShow()
        helpVC.didMove(toParent: self)
    }
}
