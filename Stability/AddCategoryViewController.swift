//
//  AddCategoryViewController.swift
//  balance
//
//  Created by Ben Sheppard on 11/10/18.
//  Copyright © 2018 Orb Mentality. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase
import Charts

class AddCategoryViewController: UIViewController, UITextFieldDelegate,
UIViewControllerTransitioningDelegate, UINavigationControllerDelegate {
    
    let animation = AnimationController()
    
    let MAX_COLORS = 9;
    var ref:DatabaseReference?
    var categoryTextField:UITextField!

    let white = UIColor(hex:15460841)
    let gray = UIColor(hex:5263695)
    // green: 8BB174
    lazy var colors = ["YLW",
                       "RED",
                       "BLUE",
                       "TEAL",
                       "PINK",
                       "VIO",
                       "NAVY",
                       "ORG",
                       "GRN"]
    
    var colors_int = [13084226,
                      16463424,
                      38099,
                      3131322,
                      16739771,
                      8007788,
                      4022498,
                      16748544,
                      4306490]
    /*lazy var colors_int = [65535, 16728064, 16760576,
                           8388863, 16741363, 7602058,
                           16743027, 16034113]*/
    var colorPicked: Int = 0
    
    
    func setupView() {
        //initial positions
        let screensize: CGRect = UIScreen.main.bounds
        let width = screensize.width
        let height = screensize.height
        
        self.view.frame = CGRect(x: 0, y: height, width: width, height: 3*height/4 + 10)
        
        //create cancel button
        let cancelButton = UIButton(type: .custom)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(white, for: .normal)
        cancelButton.setTitleColor(UIColor.black.withAlphaComponent(0.8), for: .highlighted)
        cancelButton.frame = CGRect(x: 10, y: 0, width: 60, height: 60)
        cancelButton.addTarget(self, action: #selector(AddCategoryViewController.CancelClicked), for: .touchUpInside)
        
        //create save button
        let saveButton = UIButton(type: .custom)
        saveButton.setTitle("Save", for: .normal)
        saveButton.setTitleColor(white, for: .normal)
        saveButton.setTitleColor(UIColor.black.withAlphaComponent(0.8), for: .highlighted)
        saveButton.frame = CGRect(x: width - 70, y: 0, width: 60, height: 60)
        saveButton.addTarget(self, action:#selector(AddCategoryViewController.SaveClicked), for: .touchUpInside)
        
        self.view.addSubview(cancelButton)
        self.view.addSubview(saveButton)
    }
    //destroy view
    @objc func CancelClicked() {
        self.animHide()
    }
    //save category
    @objc func SaveClicked() {
        //save to database
        guard let text = self.categoryTextField.text else {
            print("can't get text!!!")
            return
        }
        if text != "" {
            ref?.child(USER_PATH + "/categories/\(text)/").setValue(["Color" : colorPicked,
                                                           "Name" : text,
                                                           "Tasks" : ""])
            categoryTextField.text = ""
            
            // placeholder for adding (should probably add an initializer...
            let categoryToAdd = TotalTime()
            categoryToAdd.duration = 0.0
            categoryToAdd.name = text
            categoryToAdd.color = colorPicked
            
            totalTimes.append(categoryToAdd) // adds category to total time tracker
            
            try! uirealm.write {
                uirealm.add(categoryToAdd)
            }
            if let rootViewController = navigationController?.viewControllers.first as? RootPageViewController {
                let taskViewController = rootViewController.viewControllerList[2] as? TaskViewController
                taskViewController?.fetchData()
                taskViewController?.scrollView.removeFromSuperview()
                taskViewController?.createScrollView()
            }
        }
        self.animHide()
    }
    
    //create newTask textfield and keyboard
    func createTextField() {
        let screensize: CGRect = UIScreen.main.bounds
        let screenWidth = screensize.width
        let screenHeight = screensize.height
        
        categoryTextField = UITextField(frame: CGRect(x: 20, y: screenHeight/10, width: screenWidth - 40, height: 60))
        categoryTextField.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        categoryTextField.layer.borderWidth = 0.0
        //categoryTextField.backgroundColor = white
        categoryTextField.borderStyle = .roundedRect
        categoryTextField.placeholder = "Type category name..."
        categoryTextField.font = UIFont(name: "Futura", size: 20)
        categoryTextField.textColor = white
        categoryTextField.keyboardAppearance = .dark
        view.addSubview(categoryTextField)
    }
    
    @objc func buttonTapped(sender: UIButton) {
        //color
        guard let name = sender.currentTitle else {
            print("no name to choose from")
            return
        }
        guard let color = sender.backgroundColor else {
            print("no color to choose from")
            return
        }
        let index = colors.firstIndex(of: name)
        colorPicked = colors_int[index!]
        view.backgroundColor = color
    }
    
    //add color buttons
    func addButtons() {
        var i = 0
        while i < MAX_COLORS {
            let button = UIButton(type: .custom)
            if i < 3 {
                let x_pos = (45 + i*100)
                let y_pos = UIScreen.main.bounds.height/4
                button.frame = CGRect(x: x_pos, y: Int(y_pos), width: 90, height: 90)
            }
            else if i < 6 {
                let x_pos = (45 + (i - 3)*100)
                let y_pos = UIScreen.main.bounds.height/4 + 100
                button.frame = CGRect(x: x_pos, y: Int(y_pos), width: 90, height: 90)
            } else {
                let x_pos = (45 + (i - 6)*100)
                let y_pos = UIScreen.main.bounds.height/4 + 200
                button.frame = CGRect(x: x_pos, y: Int(y_pos), width: 90, height: 90)
            }
            button.layer.cornerRadius = 0.5 * button.bounds.size.width
            button.clipsToBounds = true
            
            button.setTitle(colors[i], for: .normal)
            button.titleLabel?.font = UIFont(name:"Futura", size: 30)
            button.setTitleColor(UIColor.black.withAlphaComponent(0.4), for: .normal)
            button.backgroundColor = NSUIColor(hex: colors_int[i])
            
            button.addTarget(self, action: #selector(buttonTapped(sender:)),
                             for: .touchUpInside)
            
            view.addSubview(button)
            i += 1
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
        setupView()
        createTextField()
        addButtons()
        
        self.view.layer.cornerRadius = 10.0
        view.backgroundColor = gray
        self.hideKeyboardWhenTappedAround()
    }
}

extension UIViewController {
    func animShow(){
        UIView.animate(withDuration: 0.33, delay: 0, options: [.curveEaseInOut],
                       animations: {
                        self.view.center.y -= self.view.bounds.height - 10
                        self.view.layoutIfNeeded()
        }, completion: nil)
        self.view.isHidden = false
    }
    func animHide(){
        UIView.animate(withDuration: 0.33, delay: 0, options: [.curveEaseInOut],
                       animations: {
                        self.view.center.y += self.view.bounds.height
                        self.view.layoutIfNeeded()
                        
        },  completion: {(_ completed: Bool) -> Void in
            self.view.isHidden = true
            self.view.removeFromSuperview()
            self.removeFromParent()
        })
    }
}
