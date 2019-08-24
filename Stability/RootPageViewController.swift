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
        
        let secondVC = viewControllerList[1]
        self.setViewControllers([secondVC], direction: .forward, animated: true, completion: nil)
        self.dataSource = self
    }
}
