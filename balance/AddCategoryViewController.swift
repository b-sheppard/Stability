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

class AddCategoryViewController: UIViewController, UITextFieldDelegate {
    let MAX_COLORS = 9;
    var ref:DatabaseReference?
    var categoryTextField:UITextField!

    lazy var colors = ["yellow",
                       "red",
                       "blue",
                       "green",
                       "pink",
                       "purple",
                       "b2",
                       "orange",
                        "o2"]
    
    var colors_int = [14596161,
                      16463424,
                      2390944,
                      12120806,
                      16746716,
                      8354991,
                      65535,
                      16754334,
                      16746513]
    /*lazy var colors_int = [65535, 16728064, 16760576,
                           8388863, 16741363, 7602058,
                           16743027, 16034113]*/
    var colorPicked: Int = 0
    
    
    func setupView() {
        //initial positions
        let screensize: CGRect = UIScreen.main.bounds
        let width = screensize.width
        let height = screensize.height
        
        self.view.frame = CGRect(x: 0, y: height/20, width: width, height: height)
        
        //create cancel button
        let cancelButton = UIButton(type: .custom)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.black, for: .normal)
        cancelButton.frame = CGRect(x: 10, y: 0, width: 60, height: 60)
        cancelButton.tintColor = .black
        cancelButton.addTarget(self, action: #selector(AddCategoryViewController.CancelClicked), for: .touchUpInside)
        cancelButton.tintColor = .black
        
        //create save button
        let saveButton = UIButton(type: .custom)
        saveButton.setTitle("Save", for: .normal)
        saveButton.setTitleColor(.black, for: .normal)
        saveButton.frame = CGRect(x: width - 70, y: 0, width: 60, height: 60)
        saveButton.tintColor = .black
        saveButton.addTarget(self, action:#selector(AddCategoryViewController.SaveClicked), for: .touchUpInside)
        cancelButton.tintColor = .black
        
        self.navigationController?.isNavigationBarHidden = true
        self.view.addSubview(cancelButton)
        self.view.addSubview(saveButton)
    }
    //destroy view
    @objc func CancelClicked() {
        self.navigationController?.isNavigationBarHidden = false
        print("cancel")
        self.view.removeFromSuperview()
        self.removeFromParent()
    }
    //save category
    @objc func SaveClicked() {
        self.navigationController?.isNavigationBarHidden = false
        print("save")
        //save to database
        guard let text = self.categoryTextField.text else {
            print("can't get text!!!")
            return
        }
        if text != "" {
            print("Add " + text)
            ref?.child(USER_PATH + "/categories/\(text)/").setValue(["Color" : colorPicked,
                                                           "Name" : text,
                                                           "Tasks" : ""])
            categoryTextField.text = ""
        }
        self.view.removeFromSuperview()
        self.removeFromParent()
    }
    
    //create newTask textfield and keyboard
    func createTextField() {
        let screensize: CGRect = UIScreen.main.bounds
        let screenWidth = screensize.width
        let screenHeight = screensize.height
        
        categoryTextField = UITextField(frame: CGRect(x: 20, y: screenHeight/10, width: screenWidth - 40, height: 60))
        categoryTextField.backgroundColor = .white
        categoryTextField.borderStyle = .roundedRect
        categoryTextField.placeholder = "Type category name..."
        categoryTextField.font = UIFont.systemFont(ofSize: 20.0);
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
                let x_pos = (40 + i*100)
                let y_pos = UIScreen.main.bounds.height/4
                button.frame = CGRect(x: x_pos, y: Int(y_pos), width: 90, height: 90)
            }
            else if i < 6 {
                let x_pos = (40 + (i - 3)*100)
                let y_pos = UIScreen.main.bounds.height/4 + 100
                button.frame = CGRect(x: x_pos, y: Int(y_pos), width: 90, height: 90)
            } else {
                let x_pos = (40 + (i - 6)*100)
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
        view.backgroundColor = .white
        self.hideKeyboardWhenTappedAround()
    }
}
