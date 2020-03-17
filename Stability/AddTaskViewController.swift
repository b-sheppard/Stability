//
//  AddTaskViewController.swift
//  balance
//
//  Created by Ben Sheppard on 11/16/18.
//  Copyright © 2018 Orb Mentality. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase

class AddTaskViewController: UIViewController, UITextFieldDelegate {
    let white = UIColor(hex:15460841)
    let gray = UIColor(hex:5263695)
    
    var color:UIColor!
    var ref:DatabaseReference?
    var taskTextField:UITextField!
    var timePicker: UIDatePicker!
    var taskName:String = "Add a Task"
    var path:String!
    var isOld:Bool = false
    
    let secondaryColor = UIColor.black.withAlphaComponent(0.4)
    
    func setupView() {
        //initial positions
        let screensize: CGRect = UIScreen.main.bounds
        let width = screensize.width
        let height = screensize.height
        
        self.view.frame = CGRect(x: 0, y: height, width: width, height: 97*height/100)
        
        //create cancel button
        let cancelButton = UIButton(type: .custom)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(white, for: .normal)
        cancelButton.setTitleColor(secondaryColor, for: .highlighted)
        cancelButton.frame = CGRect(x: 10, y: 0, width: 60, height: 60)
        cancelButton.tintColor = secondaryColor
        cancelButton.addTarget(self, action: #selector(AddCategoryViewController.CancelClicked), for: .touchUpInside)
        
        //create save button
        let saveButton = UIButton(type: .custom)
        saveButton.setTitle("Save", for: .normal)
        saveButton.setTitleColor(white, for: .normal)
        saveButton.setTitleColor(secondaryColor, for: .highlighted)
        saveButton.frame = CGRect(x: width - 70, y: 0, width: 60, height: 60)
        saveButton.tintColor = secondaryColor
        saveButton.addTarget(self, action:#selector(AddCategoryViewController.SaveClicked), for: .touchUpInside)
        
        //title ("Add Task" by default)
        let title = UILabel(frame: CGRect(x: (width/2 - 100), y: -10, width: 200, height: 80))
        title.text = taskName
        title.textAlignment = .center
        title.font = UIFont(name: "Futura", size: 20)
        title.textColor = secondaryColor
        
        
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
        label.frame = CGRect(x:20, y: Int(height/4) - 20, width: 100, height: 20)
        label.text = "Duration"
        label.textColor = secondaryColor
        label.font = UIFont(name: "Futura", size: 20)
        view.addSubview(label)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let dateString = "01:00"
        let date = dateFormatter.date(from:dateString)
        
        timePicker = UIDatePicker(frame: CGRect(x: 0, y: Int(height/4), width: Int(width), height: Int(height/4)))
        timePicker.backgroundColor = color
        timePicker.datePickerMode = .countDownTimer
        timePicker.setValue(gray, forKeyPath: "textColor")
        timePicker.setValue(false, forKey: "highlightsToday")
        timePicker.setDate(date ?? Date(), animated: false)
        timePicker.setValue(secondaryColor, forKeyPath: "textColor")
        
        view.addSubview(timePicker)
        
    }
    
    
    //destroy view
    @objc func CancelClicked() {
        navigationController?.setNavigationBarHidden(false, animated: false)
        self.animHide()
    }
    
    //save category
    @objc func SaveClicked() {
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
            
            ref?.child(USER_PATH + "/categories").child(path).child(text).setValue(3600*hour + 60*minute)
            taskTextField.text = ""
        }
        navigationController?.setNavigationBarHidden(false, animated: false)
        self.animHide()
    }
    
    //create newTask textfield and keyboard
    func createTextField() {
        let screensize: CGRect = UIScreen.main.bounds
        let screenWidth = screensize.width
        let screenHeight = screensize.height
        
        taskTextField = UITextField(frame: CGRect(x: 20, y: screenHeight/10, width: screenWidth - 40, height: 60))
        taskTextField.backgroundColor = color
        taskTextField.borderStyle = .roundedRect
        //let str = NSAttributedString(string: "Give your task a name...", attributes: [NSAttributedString.Key.foregroundColor: white])
        taskTextField.attributedPlaceholder = NSAttributedString(string: "Give your task a name...",
        attributes: [NSAttributedString.Key.foregroundColor: secondaryColor])
        taskTextField.font = UIFont(name: "Futura", size: 20)
        taskTextField.textColor = white
        taskTextField.keyboardAppearance = .dark
        view.addSubview(taskTextField)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
        let downSwipe = UISwipeGestureRecognizer(target: self, action: #selector(CancelClicked))
        downSwipe.direction = .down
        view.addGestureRecognizer(downSwipe)
        
        setupView()
        createTextField()
        setupPicker()
        
        self.view.layer.cornerRadius = 10.0
        view.backgroundColor = color
        self.hideKeyboardWhenTappedAround()
    }
}
