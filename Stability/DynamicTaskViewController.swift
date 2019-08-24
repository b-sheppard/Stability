//
//  DynamicTaskViewController.swift
//  balance
//
//  Created by Ben Sheppard on 07/24/19.
//  Copyright © 2018 Orb Mentality. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase

class DynamicTaskViewController: UIViewController, UITextFieldDelegate {
    var color:UIColor!
    var ref:DatabaseReference?
    var taskTextField:UITextField!
    var timePicker: UIDatePicker!
    var taskName:String!
    var taskValue:Int!
    var category:String!
    
    let white = UIColor(hex:15460841)
    let gray = UIColor(hex:5263695)
    let secondaryColor = UIColor.black.withAlphaComponent(0.4)
    
    func setupView() {
        //initial positions
        let screensize: CGRect = UIScreen.main.bounds
        let width = screensize.width
        let height = screensize.height
        
        self.view.frame = CGRect(x: 0, y: 0, width: width, height: height)
        //create cancel button
        let cancelButton = UIButton(type: .custom)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(secondaryColor, for: .normal)
        cancelButton.frame = CGRect(x: 10, y: 3*height/100, width: 60, height: 60)
        cancelButton.addTarget(self, action: #selector(AddCategoryViewController.CancelClicked), for: .touchUpInside)
        cancelButton.tintColor = secondaryColor
        
        //create save button
        let saveButton = UIButton(type: .custom)
        saveButton.setTitle("Save", for: .normal)
        saveButton.setTitleColor(secondaryColor, for: .normal)
        saveButton.frame = CGRect(x: width - 70, y: 3*height/100, width: 60, height: 60)
        saveButton.tintColor = secondaryColor
        saveButton.addTarget(self, action:#selector(AddCategoryViewController.SaveClicked), for: .touchUpInside)        
        
        self.navigationController?.isNavigationBarHidden = true
        self.view.addSubview(cancelButton)
        self.view.addSubview(saveButton)
    }
    
    func setupPicker() {
        // setup default picker time (1 hour)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let dateString = "01:00"
        let date = dateFormatter.date(from:dateString)
        let screensize: CGRect = UIScreen.main.bounds
        let width = screensize.width
        let height = screensize.height
        
        let label = UILabel()
        label.frame = CGRect(x:20, y: Int(height/4) - 30, width: 100, height: 20)
        label.text = "Duration"
        label.textColor = secondaryColor
        view.addSubview(label)
        
        
        timePicker = UIDatePicker(frame: CGRect(x: 0, y: Int(height/4), width: Int(width), height: Int(height/4)))
        timePicker.backgroundColor = color
        timePicker.datePickerMode = .countDownTimer
        timePicker.setDate(date ?? Date(), animated: false)
        timePicker.setValue(secondaryColor, forKeyPath: "textColor")

        view.addSubview(timePicker)
        
    }
    
    
    //destroy view
    @objc func CancelClicked() {
        self.navigationController?.isNavigationBarHidden = false
        navigationController?.popViewController(animated: true)
    }
    //save category
    @objc func SaveClicked() {
        self.navigationController?.isNavigationBarHidden = false
        //save to database
        guard let text = self.taskTextField.text else {
            print("can't get text!!!")
            return
        }
        if text != taskName {
            // Remove old node
            ref?.child(USER_PATH + "/categories").child(category!).child("Tasks").child(taskName!).removeValue()
            
            // Add new node
            let date = timePicker.date
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            let hour = components.value(for: .hour)!
            let minute = components.value(for: .minute)!
            
            ref?.child(USER_PATH + "/categories").child(category!).child("Tasks").child(text).setValue(3600*hour + 60*minute)
            taskTextField.text = text
        }
        navigationController?.popViewController(animated: true)
    }
    
    //create newTask textfield and keyboard
    func createTextField() {
        let screensize: CGRect = UIScreen.main.bounds
        let screenWidth = screensize.width
        let screenHeight = screensize.height
        
        taskTextField = UITextField(frame: CGRect(x: 20, y: screenHeight/10, width: screenWidth - 40, height: 60))
        taskTextField.backgroundColor = color
        taskTextField.borderStyle = .roundedRect
        taskTextField.text = taskName
        taskTextField.textAlignment = .center
        taskTextField.textColor = secondaryColor
        taskTextField.font = UIFont(name:"Futura", size:20)
        taskTextField.keyboardAppearance = .dark
        view.addSubview(taskTextField)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
        setupView()
        createTextField()
        setupPicker()
        
        view.backgroundColor = color
        self.hideKeyboardWhenTappedAround()
    }
}
