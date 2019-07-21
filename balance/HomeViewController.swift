//
//  HomeViewController.swift
//  balance
//
//  Created by Ben Sheppard on 11/19/18.
//  Copyright © 2018 Orb Mentality. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase
import Charts
import FirebaseAuth


class HomeViewController: UIViewController, ChartViewDelegate {
    let white = UIColor(hex:15460841)
    let gray = UIColor(hex:5263695)
    
    //database variables
    var ref:DatabaseReference?
    var handle:DatabaseHandle?
    var circleView: PieChartView!
    
    //color variables
    let gold = NSUIColor(hex: 16766720) //gold color
    
    //active category variables
    var categoryPosition: Dictionary = [String:String]()
    var timeOf: Dictionary = [String:Int]()
    var colorOf: Dictionary = [String:NSUIColor]()
    var selected = "Unscheduled"
    var mainButton: UIButton!
    var restartButton: UIButton!
    var selectedTaskName = UILabel()
    var descriptionLabel = UILabel()
    
    //timer variables
    var timer: Timer?
    
    var active_categories = [Category]()
    
    var resumeTapped = false
    
    
    //==========================================
    //          SCHEDULED TIMER
    //==========================================
    
    @objc public func longPress() {
        descriptionLabel.textColor = white
        if balanceTimer.categorySelected != "Unscheduled" {
            let predicate = NSPredicate(format: "name = %@", balanceTimer.taskSelected)
            let toDelete = uirealm.objects(Task.self).filter(predicate).first!
            toDelete.deleteTask()
            
            descriptionLabel.textColor = white
            mainButton.setTitle("START", for: .normal)
            let checkStatus = uirealm.objects(TimerStatus.self).first

            try! uirealm.write {
                checkStatus?.timerRunning = false
            }
            fetchData()
            updateChart()
        }
    }
    @objc public func startTapped() {
        let checkStatus = uirealm.objects(TimerStatus.self).first
        if !checkStatus!.timerRunning && balanceTimer.categoryStaged != "" {
            mainButton.setTitle("STOP", for: .normal)
            descriptionLabel.textColor = gray

            //stop unscheduled timer
            let timeRemaining = balanceTimer.stopScheduled()
            
            //update time remaining
            let predicate = NSPredicate(format: "name = %@", balanceTimer.categorySelected)
            let runningCategory = uirealm.objects(Category.self).filter(predicate).first
            
            try! uirealm.write {
                checkStatus?.timerRunning = true
                runningCategory!.duration = balanceTimer.timeRemaining
            }
            // assign new timer
            balanceTimer.categorySelected = balanceTimer.categoryStaged
            balanceTimer.categoryStaged = ""
            let PREDICATE = NSPredicate(format: "name = %@",balanceTimer.categorySelected)
            let newCategory = uirealm.objects(Category.self).filter(PREDICATE).first
            
            let taskPredicate = NSPredicate(format: "name = %@", balanceTimer.taskSelected)
            let newTask = uirealm.objects(Task.self).filter(taskPredicate).first
            
            balanceTimer.categorySelected = newCategory!.name
            balanceTimer.timeRemaining = newCategory!.duration
            balanceTimer.taskSelected = newTask!.name
            balanceTimer.timeRemainingInTask = newTask!.duration
            balanceTimer.startScheduled()
        }
        else if checkStatus!.timerRunning {
            descriptionLabel.textColor = white

            mainButton.setTitle("START", for: .normal)
            let timeRemaining = balanceTimer.stopScheduled()

            // current time remaining
            let PREDICATE = NSPredicate(format: "name = %@",balanceTimer.categorySelected)
            let runningCategory = uirealm.objects(Category.self).filter(PREDICATE).first
            
            let taskPredicate = NSPredicate(format: "name = %@", balanceTimer.taskSelected)
            let runningTask = uirealm.objects(Task.self).filter(taskPredicate).first
            
            try! uirealm.write {
                checkStatus?.timerRunning = false
                runningCategory!.duration = balanceTimer.timeRemaining
                runningTask!.duration = balanceTimer.timeRemainingInTask
            }
            // start free-time timer
            let predicate = NSPredicate(format: "name = %@", "Unscheduled")
            let unscheduled = uirealm.objects(Category.self).filter(predicate).first
            balanceTimer.categorySelected = "Unscheduled"
            balanceTimer.timeRemaining = unscheduled!.duration
            balanceTimer.taskSelected = "Unscheduled"
            balanceTimer.timeRemainingInTask = unscheduled!.duration
            balanceTimer.startScheduled()
            
        }
    }
 
    
    //==========================================
    //          BUTTON FUNCTIONS
    //==========================================
    
    @objc func addButtonTapped() {
        navigationController?.navigationBar.barTintColor = gray
        let taskViewController = TaskViewController()
        navigationController?.pushViewController(taskViewController, animated: true)
    }
    
    
    
    //==========================================
    //          CHART FUNCTIONS
    //==========================================
    //gets name of selected chart
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        let c = categoryPosition[String(Int(entry.x))]!
        goToCategory(category: c)
    }
    
    //goes to active tasks in category
    func goToCategory(category: String) {
        let categoryView = ActiveTaskViewController()
        categoryView.name = category
        
        //go to add task section if gray area is tapped
        if category == "Unscheduled" {
            addButtonTapped()
        }
        //go to add task section if gold area is tapped
        else if category == "Completed" {
            addButtonTapped()
        }
            
        else {
            //assign color to category
            ref?.child(USER_PATH + "/categories").child(category).child("Color")
                .observeSingleEvent(of: .value, with: { (snapshot) in
                    let color = NSUIColor(hex: snapshot.value! as! Int)
                    categoryView.color = color
                })
            
            //go to new view
            navigationController?.pushViewController(categoryView, animated: false)
        }
    }
    @objc func goToProfile() {
        let profile = ProfileViewController()
        navigationController?.pushViewController(profile, animated: false)
    }
    @objc func taskFinished() {
        // task has finished
        balanceTimer.tasksCompleted += 1
        let unscheduled = uirealm.objects(Category.self).filter("name = 'Unscheduled'").first!
        let checkStatus = uirealm.objects(TimerStatus.self).first!
        
        let categoryPredicate = NSPredicate(format: "name = %@", balanceTimer.categorySelected)
        let taskPredicate = NSPredicate(format: "name = %@", balanceTimer.taskSelected)
        let categoryToDelete = uirealm.objects(Category.self).filter(categoryPredicate).first!
        let taskToDelete = uirealm.objects(Task.self).filter(taskPredicate).first!
        var secondsOvertime = 0
        
        // last task in category finished
        if(balanceTimer.timeRemaining <= 0) {
            secondsOvertime = unscheduled.duration + balanceTimer.timeRemaining
            try! uirealm.write {
                checkStatus.timerRunning = false
                checkStatus.currentCategory = "Unscheduled"
                checkStatus.currentTask = "Unscheduled"
                uirealm.delete(categoryToDelete)
                uirealm.delete(taskToDelete)
            }
        }
        // not last task in category
        else if(balanceTimer.timeRemainingInTask <= 0) {
            secondsOvertime = unscheduled.duration + balanceTimer.timeRemainingInTask
            try! uirealm.write {
                checkStatus.timerRunning = false
                checkStatus.currentCategory = "Unscheduled"
                checkStatus.currentTask = "Unscheduled"
                uirealm.delete(taskToDelete)
            }
        }
        
        balanceTimer.timeRemaining = secondsOvertime
        balanceTimer.timeRemainingInTask = secondsOvertime
        balanceTimer.categorySelected = "Unscheduled"
        balanceTimer.taskSelected = "Unscheduled"
        
        //balanceTimer.startScheduled()
        mainButton.setTitle("START", for: .normal)
        fetchData()
    }
    // time exceeds 24 hours
    func restartAllTimers() {
        // restart balance timer
        balanceTimer.categorySelected = "Unscheduled"
        balanceTimer.categoryStaged = ""
        balanceTimer.tasksCompleted = 0
        // find time interval of user set time
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let timeInterval = 3600*(hour - balanceTimer.hourStarted) + 60*(minute - balanceTimer.minuteStarted)
        balanceTimer.timeRemaining = 86400 - timeInterval
        balanceTimer.timeRemainingInTask = 86400 - timeInterval
        balanceTimer.secondsCompleted = Double(timeInterval)
        balanceTimer.taskSelected = "Unscheduled"
        selectedTaskName.text = "Select a Task"

        let unscheduled = Category()
        unscheduled.duration = 86400 - timeInterval
        unscheduled.name = "Unscheduled"
        
        let unscheduledTask = Task()
        unscheduledTask.duration = unscheduled.duration
        unscheduledTask.name = unscheduled.name
        unscheduledTask.category = "Unscheduled"
        
        let categoriesToDelete = uirealm.objects(Category.self)
        let tasksToDelete = uirealm.objects(Task.self)
        try! uirealm.write {
            uirealm.delete(categoriesToDelete)
            uirealm.delete(tasksToDelete)
            uirealm.add(unscheduled)
            uirealm.add(unscheduledTask)
        }
        
        self.view.backgroundColor = white
        circleView.backgroundColor = white
        selectedTaskName.backgroundColor = white
        descriptionLabel.backgroundColor = white
        mainButton.backgroundColor = white
        fetchData()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: #selector(self.updateChart), userInfo: nil, repeats: true)
        balanceTimer.startScheduled()
    }
    @objc func restartButtonTapped() {
        selectedTaskName.text = "Select a Task"
        self.view.backgroundColor = white
        circleView.backgroundColor = white
        selectedTaskName.backgroundColor = white
        descriptionLabel.backgroundColor = white
        mainButton.backgroundColor = white
        restartButton.removeFromSuperview()
        fetchData()
        balanceTimer.startScheduled()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: #selector(self.updateChart), userInfo: nil, repeats: true)
    }
    
    // Displayed when tasks are over
    func addRestartButton() {
        restartButton = UIButton()
        let screensize: CGRect = UIScreen.main.bounds
        restartButton.frame = CGRect(x: screensize.width/2, y: 50,
                                     width: screensize.width - 50, height: 80)
        restartButton.layer.cornerRadius = 5
        restartButton.center.x = screensize.width/2
        restartButton.setTitle("KEEP GOING", for: .normal)
        restartButton.titleLabel?.font = UIFont(name:"Futura", size: 40)
        restartButton.setTitleColor(gray, for: .normal)
        restartButton.backgroundColor = gold
        restartButton.addTarget(self, action:#selector(HomeViewController.restartButtonTapped),
                                for: .touchUpInside)
        self.view.backgroundColor = gray
        circleView.backgroundColor = gray
        selectedTaskName.backgroundColor = gray
        descriptionLabel.backgroundColor = gray
        mainButton.backgroundColor = gray
        self.view.addSubview(restartButton)
        
        //make circle gold
        balanceTimer.tasksCompleted = 0
        active_categories.removeAll()
        let completed = Category()
        completed.color = gold.rgb()!
        completed.duration = 86400
        completed.name = "Completed"
        active_categories.append(completed)
    }

    func fixSchedule() {
        // schedule cannot be fixed
        print(balanceTimer.secondsCompleted)
        if balanceTimer.secondsCompleted >= 86400 {
            timer?.invalidate()
            selectedTaskName.text = "BALANCE NOT ACHIEVED"
            selectedTaskName.textColor = white
            balanceTimer.stopScheduled()
            restartAllTimers()
            return
        }
        else {
            timer?.invalidate()
            navigationController?.navigationBar.barTintColor = gray
            let scheduleFixer = FixScheduleView()
            navigationController?.pushViewController(scheduleFixer, animated: true)
        }
        
    }
    @objc func updateChart() {
        //print(balanceTimer.timeRemainingInTask)
        if balanceTimer.timeRemainingInTask < 0 {
            if balanceTimer.categorySelected == "Unscheduled" {
                fixSchedule()
                return
            }
            else {
                taskFinished()
            }
        }
        //user finished all tasks: Display "balance achieved
        if balanceTimer.tasksCompleted > 0 && active_categories.count == 1 {
            selectedTaskName.text = "BALANCE ACHIEVED"
            balanceTimer.stopScheduled()
            timer?.invalidate()
            addRestartButton()
            updateChart()
            return
        }
        //update label above chart
        if balanceTimer.taskSelected == "Unscheduled" {
            selectedTaskName.text = "Select a Category"
        }
        else {
            selectedTaskName.text = balanceTimer.taskSelected
        }
        var categories : [PieChartDataEntry] = Array()
        
        //get times of categories
        var position = 0

        //print(active_categories)
        for cat in active_categories {
            if cat.name == "Unscheduled" {
                self.colorOf[cat.name] = gray
            }
            else {
                self.colorOf[cat.name] = NSUIColor(hex:cat.color)
            }
            let dataEntry = PieChartDataEntry(value: Double(cat.duration), label: nil)
            if cat.name == balanceTimer.categorySelected {
                dataEntry.value = Double(balanceTimer.timeRemaining)
            }
            if cat.duration <= 0 {
                dataEntry.value = 0
            }
            // should fix category display issue when 3600 is still displayed when no active task exists
            else if cat.duration <= 3600 && cat.duration > 0 && cat.name != "Unscheduled" {
                dataEntry.value = 3600.0
            }
            dataEntry.x = Double(position)
            categories.append(dataEntry)
            
            let categoryName = cat.name
            categoryPosition[String(position)] = categoryName
            position += 1
        }
        
        //create completed time placeholder
        let completedEntry = PieChartDataEntry(value: Double(balanceTimer.secondsCompleted), label: nil)
        completedEntry.x = Double(position)
        categories.append(completedEntry)
        categoryPosition[String(position)] = "Completed"
        
        let chartDataSet = PieChartDataSet(entries: categories, label: nil)
        chartDataSet.selectionShift = 0
        let chartData = PieChartData(dataSet: chartDataSet)
        var categoryColor : [NSUIColor] = []
        for cat in active_categories {
            categoryColor.append(colorOf[cat.name] ?? NSUIColor(hex: 0000000))
        }
        categoryColor.append(gold)
        
        chartDataSet.colors = categoryColor
        circleView.data = chartData
    }
    
    // updates colors (name of category as key)
    func updateColor(category: String) {
        if category == "Unscheduled" {
            self.colorOf[category] = gray
            return
        }
        ref?.child(USER_PATH + "/categories").child(category).child("Color")
            .observeSingleEvent(of: .value, with: { (snapshot) in
                let color = NSUIColor(hex: snapshot.value! as! Int)
                self.colorOf[category] = color
            })
    }
    
    //==========================================
    //          BASIC SETUP
    //==========================================
    func addButton() {
        let checkStatus = uirealm.objects(TimerStatus.self).first
        
        //tap
        let tap = UITapGestureRecognizer(target: self, action: #selector(HomeViewController.startTapped))
        //long press
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(HomeViewController.longPress))
        longPress.minimumPressDuration = 3

        mainButton = UIButton(type: .custom)
        mainButton.frame = CGRect(x: 160, y: 100, width: 200, height: 200)
        mainButton.layer.cornerRadius = 0.5 * mainButton.bounds.size.width
        mainButton.clipsToBounds = true
        mainButton.translatesAutoresizingMaskIntoConstraints = false
        mainButton.addGestureRecognizer(tap)
        mainButton.addGestureRecognizer(longPress)
        //mainButton.addTarget(self, action: #selector(HomeViewController.startTapped), for: .touchUpInside)
        if(checkStatus!.timerRunning) {
            mainButton.setTitle("STOP", for: .normal)
            descriptionLabel.textColor = gray
        }
        else {
            mainButton.setTitle("START", for: .normal)
            descriptionLabel.textColor = white

        }
        mainButton.titleLabel?.font = UIFont(name:"Futura", size: 60)
        mainButton.setTitleColor(gray, for: .normal)
        mainButton.backgroundColor = white
        
        view.addSubview(mainButton)
        
        let horizontalCenter = NSLayoutConstraint(item: mainButton, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0)
        
        let verticalCenter = NSLayoutConstraint(item: mainButton, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.0, constant: 0)
        
        let width = NSLayoutConstraint(item: mainButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 200)
        
        let height = NSLayoutConstraint(item: mainButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 200)
        
        let constraints: [NSLayoutConstraint] = [horizontalCenter, verticalCenter, width, height]
        NSLayoutConstraint.activate(constraints)
    }
    
    // creates label
    func addLabel() {
        let screensize: CGRect = UIScreen.main.bounds
        selectedTaskName.frame = CGRect(x: screensize.width/2, y: 50, width: 300, height: 50)
        selectedTaskName.center.x = screensize.width/2
        selectedTaskName.center.y = 7*screensize.height/8
        selectedTaskName.backgroundColor = white
        selectedTaskName.text = "Select a Category"
        selectedTaskName.textAlignment = .center
        selectedTaskName.textColor = gray
        selectedTaskName.font = UIFont(name: "Futura", size: 20)
        
        view.addSubview(selectedTaskName)
        
    }
    
    // creates label with description on "hold to end"
    func addDescription() {
        let screensize: CGRect = UIScreen.main.bounds
        descriptionLabel.frame = CGRect(x: screensize.width/2, y: 50, width: 300, height: 50)
        descriptionLabel.center.x = screensize.width/2
        descriptionLabel.center.y = screensize.height/8
        descriptionLabel.backgroundColor = white
        descriptionLabel.text = "Hold STOP to finish task"
        descriptionLabel.textAlignment = .center
        descriptionLabel.textColor = white
        descriptionLabel.font = UIFont(name: "Futura", size: 20)
        
        view.addSubview(descriptionLabel)
    }
    // gathers active tasks from Realm
    func fetchData() {
        let activeCategories = uirealm.objects(Category.self)
       // print(activeCategories)
        active_categories.removeAll()
        for cat in activeCategories {
            active_categories.append(cat)
        }
        
        self.colorOf["Unscheduled"] = gray
    }
    
    func setupView() {
        circleView = PieChartView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        circleView.backgroundColor = white
        circleView.clipsToBounds = true
        circleView.translatesAutoresizingMaskIntoConstraints = false
        
        //settings on pie chart
        circleView.chartDescription?.enabled = false
        circleView.drawHoleEnabled = true
        circleView.rotationAngle = 0
        circleView.rotationEnabled = true
        circleView.isUserInteractionEnabled = true
        circleView.legend.enabled = false
        //circleView.highlightPerTapEnabled = false
        view.addSubview(circleView)
        
        let horizontalCenter = NSLayoutConstraint(item: circleView, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0)
        
        let verticalCenter = NSLayoutConstraint(item: circleView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.0, constant: 0)
        
        let width = NSLayoutConstraint(item: circleView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 350)
        
        let height = NSLayoutConstraint(item: circleView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 350)
        
        let constraints: [NSLayoutConstraint] = [horizontalCenter, verticalCenter, width, height]
        NSLayoutConstraint.activate(constraints)
    
        self.circleView.delegate = self
        
        //updateChart()
    }
    
    
    //==========================================
    //          OVERRIDE FUNCTIONS
    //==========================================
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        
        // self.navigationController?.isNavigationBarHidden = true;
        
        let addTaskButton = UIBarButtonItem(title: "Add Task",
                                         style: .plain,
                                         target: self,
                                         action: #selector(HomeViewController.addButtonTapped))
        let profileButton = UIBarButtonItem(title: "Profile",
                                            style: .plain,
                                            target: self,
                                            action: #selector(HomeViewController.goToProfile))
        
        view.backgroundColor = white
        self.navigationItem.rightBarButtonItem = addTaskButton
        self.navigationItem.rightBarButtonItem?.tintColor = gray
        self.navigationItem.leftBarButtonItem = profileButton
        self.navigationItem.leftBarButtonItem?.tintColor = .red
        
        fetchData()
        setupView()
        addButton()
        addLabel()
        addDescription()
        
        selectedTaskName.text = "Select a Category"
    }

    override func viewDidAppear(_ animated: Bool) {
        fetchData()
        updateChart()
        
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: #selector(self.updateChart), userInfo: nil, repeats: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        timer?.invalidate()
    }
    
    //===========================================================
    //           OBSERVERS
    //===========================================================
    @objc func appBecameActive() {
        if balanceTimer.timeRemainingInTask <= 0 {
            if balanceTimer.categorySelected == "Unscheduled" {
                fixSchedule()
            }
            else {
                taskFinished()
            }
        }
    } //appBecameActive()
    
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(appBecameActive),
                                               name: UIApplication.didBecomeActiveNotification, object:nil)
    }
    
    func resetObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    deinit {
        resetObservers()
    }
}
