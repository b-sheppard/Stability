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
    
    var dateButton = UIButton()
    
    let scrollView = UIScrollView() // contains v1, v2, v3
    
    let v1 = UIStackView() // week
    let v2 = UIStackView() // month
    let v3 = UIStackView() // year
    
    // baked-in categories
    var categories = ["unscheduled",
                      "cat 1", "cat 2", "cat 3",
                      "cat 4", "cat 5", "cat 6",
                      "cat 7", "cat 8", "cat 9"]
    // baked-in times
    var times = ["like a billion",
                 "100", "200", "300",
                 "400", "500", "600",
                 "700", "800", "900"]
    // baked-in colors
    var colors_int = [5263695,
                      14596161,
                      16463424,
                      38099,
                      3131322,
                      16739771,
                      8007788,
                      4022498,
                      16748544,
                      4306490]
    
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
    
    func addDateButton() {
        let x_pos = width/2
        let y_pos = height/4 - 70
        dateButton.frame = CGRect(x: x_pos - 150, y: y_pos, width: 300, height: 60)
        dateButton.clipsToBounds = true
        dateButton.setTitle("Set new start time", for: .normal)
        dateButton.titleLabel?.font = UIFont(name:"Futura", size: 30)
        dateButton.setTitleColor(white, for: .normal)
        dateButton.backgroundColor = gray
        dateButton.setTitleColor(.white, for: .highlighted)
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
    
    func setupScrollView() {
        let y_pos = height/2
        let scroll_height = Int(45*height/100 - 30)
        
        scrollView.frame = CGRect(x:0, y: y_pos, width: width, height: 46*height/100)
        scrollView.backgroundColor = white
        scrollView.isUserInteractionEnabled = true
        scrollView.isScrollEnabled = true
        scrollView.contentSize = CGSize(width: width, height: 200)
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.flashScrollIndicators()
        
        v1.frame = CGRect(x: 0, y: 0, width: width, height: 200)
        
        let v1timeframe = UILabel(frame:CGRect(x:0,
                                               y: 45*height/100 - 30,
                                               width: width,
                                               height:30))
        v1timeframe.font = UIFont(name: "Futura", size: 22)
        v1timeframe.textAlignment = .center
        v1timeframe.text = "Total time spent"
        v1timeframe.textColor = gray
        v1.addSubview(v1timeframe)
        
        for pos in 0...categories.count - 1 {
            let catName = UILabel(frame:CGRect(x: 0,
                                               y: pos*scroll_height/10,
                                               width: Int(width/2) - 10,
                                               height: scroll_height/10))
            catName.adjustsFontSizeToFitWidth = true
            catName.textAlignment = .right
            catName.text = categories[pos]
            catName.textColor = UIColor(hex:colors_int[pos])
            catName.font = UIFont(name: "Futura", size: 20)
            
            let catVal = UILabel(frame:CGRect(x: Int(width/2 + 10),
                                              y: pos*scroll_height/10,
                                              width: Int(width/2) - 10,
                                              height: scroll_height/10))
            catVal.adjustsFontSizeToFitWidth = true
            catVal.textAlignment = .left
            catVal.text = times[pos]
            catVal.textColor = UIColor(hex:colors_int[pos])
            catVal.font = UIFont(name: "Futura", size: 20)
            v1.addSubview(catName)
            v1.addSubview(catVal)
        }
        scrollView.addSubview(v1)
        
        v2.frame = CGRect(x: width, y: 0, width: width, height: 200)
        v2.backgroundColor = .green
        //scrollView.addSubview(v2)
        
        v3.frame = CGRect(x: 2*width, y: 0, width: width, height: 200)
        v3.backgroundColor = .blue
        //scrollView.addSubview(v3)
        
        self.view.addSubview(scrollView)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barTintColor = white
        navigationItem.hidesBackButton = true
        
        let backButton = UIBarButtonItem(title: "Home", style: .plain, target: self, action: #selector(backTapped))
        
        let signoutButton = UIBarButtonItem(title: "Sign Out", style: .plain, target: self, action: #selector(signoutUser))
        navigationItem.rightBarButtonItem = backButton
        navigationItem.leftBarButtonItem = signoutButton
        
        view.backgroundColor = white
        
        addDateButton()
        addPicker()
        setupScrollView()
    }
}