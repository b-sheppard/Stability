//
//  MainViewController.swift
//  balance
//
//  Created by Ben Sheppard on 9/21/18.
//  Copyright © 2018 Orb Mentality. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

//[blue, pink, green, yellow, brown, gray]
//let colors : [Int] = [0x1AEEEE, 0xEE1AEE, 0x1AEE84, 0xEEEE1A, 0x900C3F, 0x808B96]

//["yellow", "red", "blue","green", "pink", "purple", "blue","gray"]
//let colors : [Int] = [16777040,16727110,3978495,0x1AEE84,16751560,10178805, 65535,10660016]
let colors = [14596161,
              16463424,
              2390944,
              12120806,
              16746716,
              8354991,
              65535,
              16746513]

class MainViewController: UIViewController {
    
    let white = UIColor(hex:15460841)
    let gray = UIColor(hex:5263695)
    
    let categoryNames = ["Work", "Health", "Social", "Sleep", "Chores", "FOO", "BAR","BAZ"]
    
    var ref:DatabaseReference?

    @objc func buttonTapped() {
        let taskViewController = TaskViewController()
        navigationController?.pushViewController(taskViewController, animated: true)
    }
    
    private func addButton() {
        let mainButton = UIButton(type: .custom)
        mainButton.frame = CGRect(x: 160, y: 100, width: 50, height: 50)
        mainButton.layer.cornerRadius = 0.5 * mainButton.bounds.size.width
        mainButton.clipsToBounds = true
        mainButton.translatesAutoresizingMaskIntoConstraints = false
        
        mainButton.addTarget(self, action: #selector(MainViewController.buttonTapped), for: .touchUpInside)
        mainButton.setTitle("+", for: .normal)
        mainButton.titleLabel?.font = UIFont(name:"Futura", size: 60)
        mainButton.setTitleColor(gray, for: .normal)
        mainButton.backgroundColor = white
        
        view.addSubview(mainButton)
        
        let horizontalCenter = NSLayoutConstraint(item: mainButton, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0)
        
        let verticalCenter = NSLayoutConstraint(item: mainButton, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.0, constant: 0)
        
        let width = NSLayoutConstraint(item: mainButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 100)
        
        let height = NSLayoutConstraint(item: mainButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 75)
        
        let constraints: [NSLayoutConstraint] = [horizontalCenter, verticalCenter, width, height]
        NSLayoutConstraint.activate(constraints)
    }
    
    func createDatabase() {
        //add category to database
        var i = 0
        while i < colors.count {
            ref?.child(USER_PATH + "/categories").child(categoryNames[i]).setValue(["Color" : colors[i],
                                                                       "Name" : categoryNames[i],
                                                                       "Tasks" : ""])
            i += 1
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        navigationController?.isNavigationBarHidden = true

        view.backgroundColor = gray
        addButton()
        createDatabase()
        
        firstTime = false
    }
}
