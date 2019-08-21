//
//  ProfileViewController.swift
//  balance
//
//  Created by Ben Sheppard on 7/16/19.
//  Copyright © 2019 Orb Mentality. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth

class ProfileViewController: UIViewController {
    let white = UIColor(hex:15460841)
    let gray = UIColor(hex:5263695)
    let width = UIScreen.main.bounds.width
    let height = UIScreen.main.bounds.height
    
    let startPicker = UIDatePicker()
    
    
    @objc func backTapped(){
        
        navigationController?.popToRootViewController(animated: true)
    }
    
    @objc func signoutUser() {
        do {
            try Auth.auth().signOut()
        }
        catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        
        let login = LoginViewController()
        navigationController?.pushViewController(login, animated: false)
    }
    
    @objc func updateStartTime() {
        let hourSelected = startPicker.calendar.component(.hour, from: startPicker.date)
        let minuteSelected = startPicker.calendar.component(.minute, from: startPicker.date)
        
        let timeDifference = 3600*(balanceTimer.hourStarted - hourSelected) + 60*(balanceTimer.minuteStarted - minuteSelected)
        
        balanceTimer.hourStarted = hourSelected
        balanceTimer.minuteStarted = minuteSelected
        
        
        let unscheduled = uirealm.objects(Category.self).filter("name = 'Unscheduled'").first
        let unscheduledTask = uirealm.objects(Task.self).filter("name = 'Unscheduled'").first
        
        balanceTimer.secondsCompleted += Double(timeDifference)
        
        // Too much time added to unscheduled (Day > 86400 seconds)
        if balanceTimer.secondsCompleted < 0 {
            let secondsOvertime = Int(-1 * balanceTimer.secondsCompleted)
            balanceTimer.secondsCompleted = Double(86400 - secondsOvertime)
            try! uirealm.write {
                unscheduled!.duration = secondsOvertime
                unscheduledTask!.duration = secondsOvertime
            }
            if balanceTimer.categorySelected == "Unscheduled" {
                balanceTimer.timeRemaining = secondsOvertime
                balanceTimer.timeRemainingInTask = secondsOvertime
            }
        }
        
        else {
            try! uirealm.write {
                unscheduled!.duration -= timeDifference
                unscheduledTask!.duration -= timeDifference
            }
            if balanceTimer.categorySelected == "Unscheduled" {
                balanceTimer.timeRemaining -= timeDifference
                balanceTimer.timeRemainingInTask -= timeDifference
            }
        }
    }
    
    func addSignoutButton() {
        let x_pos = width/2
        let y_pos = height - 80
        
        let signout = UIButton()
        signout.frame = CGRect(x: x_pos - 150, y: y_pos, width: 300, height: 60)
        signout.clipsToBounds = true
        signout.setTitle("Signout", for: .normal)
        signout.titleLabel?.font = UIFont(name:"Futura", size: 30)
        signout.setTitleColor(white, for: .normal)
        signout.backgroundColor = gray
        signout.addTarget(self, action: #selector(signoutUser), for: .touchUpInside)
        signout.layer.cornerRadius = 10
        view.addSubview(signout)
    }
    
    func addDateButton() {
        let x_pos = width/2
        let y_pos = height/2
        let dateButton = UIButton()
        dateButton.frame = CGRect(x: x_pos - 150, y: y_pos, width: 300, height: 60)
        dateButton.clipsToBounds = true
        dateButton.setTitle("Set new start time", for: .normal)
        dateButton.titleLabel?.font = UIFont(name:"Futura", size: 30)
        dateButton.setTitleColor(white, for: .normal)
        dateButton.backgroundColor = gray
        dateButton.addTarget(self, action: #selector(updateStartTime), for: .touchUpInside)
        dateButton.layer.cornerRadius = 10
        view.addSubview(dateButton)
    }
    
    func addPicker() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat =  "HH:mm"
        let dateString = String(balanceTimer.hourStarted) + ":" + String(balanceTimer.minuteStarted)
        
        let date = dateFormatter.date(from:dateString)        
        startPicker.frame = CGRect(x: 0, y: height/4, width: width, height: height/4)
        startPicker.backgroundColor = white
        startPicker.tintColor = .red
        startPicker.datePickerMode = .time
        startPicker.setDate(date ?? Date(), animated: false)
        startPicker.setValue(gray, forKeyPath: "textColor")

        
        view.addSubview(startPicker)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barTintColor = white
        navigationItem.hidesBackButton = true
        
        let backButton = UIBarButtonItem(title: "Home", style: .plain, target: self, action: #selector(backTapped))
        navigationItem.rightBarButtonItem = backButton
        
        view.backgroundColor = white
        
        addDateButton()
        addSignoutButton()
        addPicker()
    }
}
