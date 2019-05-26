//
//  TaskGenericViewController.swift
//  balance
//
//  Created by Ben Sheppard on 11/25/18.
//  Copyright © 2018 Orb Mentality. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase

class TaskGenericViewController: UIViewController, UITextFieldDelegate {
    var color:UIColor!
    var ref:DatabaseReference?
    var taskTextField:UITextField!
    var timePicker: UIDatePicker!
    var taskName:String!
    var path:String!
    
    func setupView() {
        //initial positions
        let screensize: CGRect = UIScreen.main.bounds
        let width = screensize.width
        let height = screensize.height
        
        self.view.frame = CGRect(x: 0, y: 40, width: width, height: height)
        
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
        
        //title ("New Task" by default)
        let title = UILabel(frame: CGRect(x: (width/2 - 100), y: 0, width: 200, height: 80))
        title.text = taskName
        title.textAlignment = .center
        
        
        self.navigationController?.isNavigationBarHidden = true
        self.view.addSubview(cancelButton)
        self.view.addSubview(saveButton)
        self.view.addSubview(title)
    }
    
    func setupPicker() {
        let screensize: CGRect = UIScreen.main.bounds
        let width = screensize.width
        let height = screensize.height
        
        let label = UILabel()
        label.frame = CGRect(x:20, y: Int(height/4) - 30, width: 100, height: 20)
        label.text = "Duration"
        label.textColor = .black
        view.addSubview(label)
        
        
        timePicker = UIDatePicker(frame: CGRect(x: 0, y: Int(height/4), width: Int(width), height: Int(height/4)))
        timePicker.backgroundColor = .white
        timePicker.datePickerMode = .countDownTimer
        
        view.addSubview(timePicker)
        
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
        //save to database
        guard let text = self.taskTextField.text else {
            print("can't get text!!!")
            return
        }
        if text != "" {
            print("Add " + text)
            let date = timePicker.date
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            let hour = components.value(for: .hour)!
            let minute = components.value(for: .minute)!
            
            ref?.child(USER_PATH + "/categories").child(path).child(text).setValue(60*hour + minute)
            taskTextField.text = ""
        }
        self.view.removeFromSuperview()
        self.removeFromParent()
    }
    
    //create newTask textfield and keyboard
    func createTextField() {
        let screensize: CGRect = UIScreen.main.bounds
        let screenWidth = screensize.width
        let screenHeight = screensize.height
        
        taskTextField = UITextField(frame: CGRect(x: 20, y: screenHeight/10, width: screenWidth - 40, height: 60))
        taskTextField.backgroundColor = .white
        taskTextField.borderStyle = .roundedRect
        taskTextField.placeholder = "Give your task a name..."
        taskTextField.font = UIFont.systemFont(ofSize: 20.0);
        taskTextField.keyboardAppearance = .dark
        view.addSubview(taskTextField)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
        setupView()
        createTextField()
        setupPicker()
        
        self.view.layer.cornerRadius = 10.0
        view.backgroundColor = color
        self.hideKeyboardWhenTappedAround()
    }
}