//
//  HelpViewController.swift
//  Stability
//
//  Created by Ben Sheppard on 8/27/19.
//  Copyright © 2019 Orb Mentality. All rights reserved.
//

import Foundation
import UIKit

class HelpViewController: UIViewController {
    let white = UIColor(hex:15460841)
    let gray = UIColor(hex:5263695)
    
    let width = UIScreen.main.bounds.width
    let height = UIScreen.main.bounds.height
    let viewHeight = UIScreen.main.bounds.height - 10
    
    func setupView() {
        // view size
        self.view.frame = CGRect(x: 0, y: height, width: width, height: viewHeight)
        
        // close button
        let closeButton = UIButton(type: .custom)
        closeButton.setTitle("Close", for: .normal)
    closeButton.setTitleColor(UIColor.black.withAlphaComponent(0.4), for: .normal)
        closeButton.frame = CGRect(x: width - 70, y: 10, width: 60, height: 60)
        closeButton.addTarget(self, action: #selector(HelpViewController.CloseView), for: .touchUpInside)
        
        self.view.addSubview(closeButton)
        
        // help text
        let help = UITextView(frame: CGRect(x:10, y: 50, width: width - 10, height: viewHeight))
        help.backgroundColor = gray
        help.textColor = white
        help.font = UIFont(name: "Futura", size: 20)
        
        help.text = """
            1. Add a new category (sleep already exists)\n
            2. Add a new task to a category (e.g. "nap" in sleep)\n
            3. Add a task to your day with the serach bar\n
            4. Make a task active by tapping the category section in the pie chart\n
            5. Press START\n
            Additional info:
            Edit a task by tapping the row when in a category\n
            Set a new start time of the 24-hour period with the "Set new start time" button
            """

        
        self.view.addSubview(help)
    }
    
    @objc func CloseView() {
        self.animHide()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        
        self.view.layer.cornerRadius = 10.0
        view.backgroundColor = gray
    }
}
