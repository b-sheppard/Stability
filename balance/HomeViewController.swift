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


class HomeViewController: UIViewController, ChartViewDelegate {
    //database variables
    var ref:DatabaseReference?
    var handle:DatabaseHandle?
    var circleView: PieChartView!
    
    //color variables
    let gray = NSUIColor(hex: 8424342) //gray color
    let gold = NSUIColor(hex: 16766720) //gold color
    
    //active category variables
    var categoryPosition: Dictionary = [String:String]()
    var timeOf: Dictionary = [String:Int]()
    var colorOf: Dictionary = [String:NSUIColor]()
    var selected = "Unscheduled"
    var mainButton: UIButton!
    var selectedTaskName = UILabel()
    
    //timer variables
    var timer: Timer?
    
    var active_categories = [Category]()
    
    var resumeTapped = false
    
    
    //==========================================
    //          SCHEDULED TIMER
    //==========================================
    @objc public func startTapped() {
        let checkStatus = uirealm.objects(TimerStatus.self).first

        if !checkStatus!.timerRunning && balanceTimer.categoryStaged != "" {
            mainButton.setTitle("STOP", for: .normal)
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
        print("Go to Task")
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
    @objc func taskFinished() {
        // task has finished
        // print(balanceTimer.timeRemaining)
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
        balanceTimer.secondsRunning = 0
        balanceTimer.categorySelected = "Unscheduled"
        balanceTimer.taskSelected = "Unscheduled"
        
        //balanceTimer.startScheduled()
        balanceTimer.taskFinished = false
        mainButton.setTitle("START", for: .normal)
        fetchData()
    }

    
    @objc func updateChart() {
        //print(balanceTimer.timeRemainingInTask)
        if(balanceTimer.timeRemainingInTask <= 0) {
            taskFinished()
        }
        
        var categories : [PieChartDataEntry] = Array()
        
        //get times of categories
        var position = 0

        //print(active_categories)
        for cat in active_categories {
            let dataEntry = PieChartDataEntry(value: Double(cat.duration), label: nil)
            if cat.name == balanceTimer.categorySelected {
                dataEntry.value = Double(balanceTimer.timeRemaining)
            }
            if cat.duration == 0 {
                dataEntry.value = 0
            }
            else if cat.duration <= 3600 {
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

        mainButton = UIButton(type: .custom)
        mainButton.frame = CGRect(x: 160, y: 100, width: 200, height: 200)
        mainButton.layer.cornerRadius = 0.5 * mainButton.bounds.size.width
        mainButton.clipsToBounds = true
        mainButton.translatesAutoresizingMaskIntoConstraints = false
        mainButton.addTarget(self, action: #selector(HomeViewController.startTapped), for: .touchUpInside)
        if(checkStatus!.timerRunning) {
            mainButton.setTitle("STOP", for: .normal)
        }
        else {
            mainButton.setTitle("START", for: .normal)
        }
        mainButton.titleLabel?.font = UIFont(name:"Futura", size: 60)
        mainButton.setTitleColor(.black, for: .normal)
        mainButton.backgroundColor = .white
        
        view.addSubview(mainButton)
        
        let horizontalCenter = NSLayoutConstraint(item: mainButton, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0)
        
        let verticalCenter = NSLayoutConstraint(item: mainButton, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.0, constant: 0)
        
        let width = NSLayoutConstraint(item: mainButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 200)
        
        let height = NSLayoutConstraint(item: mainButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 200)
        
        let constraints: [NSLayoutConstraint] = [horizontalCenter, verticalCenter, width, height]
        NSLayoutConstraint.activate(constraints)
    }
    
    //creates label
    func addLabel() {
        let screensize: CGRect = UIScreen.main.bounds
        selectedTaskName.frame = CGRect(x: screensize.width/2, y: 50, width: 300, height: 50)
        selectedTaskName.center.x = screensize.width/2
        selectedTaskName.center.y = screensize.height/7
        selectedTaskName.backgroundColor = .white
        selectedTaskName.text = "Select a task"
        selectedTaskName.textAlignment = .center
        selectedTaskName.textColor = .black
        
        view.addSubview(selectedTaskName)
        
    }
    // gathers active tasks from Realm
    func fetchData() {
        let activeCategories = uirealm.objects(Category.self)
        active_categories.removeAll()
        for cat in activeCategories {
            active_categories.append(cat)
        }
        
        self.colorOf["Unscheduled"] = gray
    }
    
    func setupView() {
        circleView = PieChartView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        circleView.backgroundColor = .white
        circleView.clipsToBounds = true
        circleView.translatesAutoresizingMaskIntoConstraints = false
        
        //settings on pie chart
        circleView.chartDescription?.enabled = false
        circleView.drawHoleEnabled = true
        circleView.rotationAngle = 0
        circleView.rotationEnabled = true
        circleView.isUserInteractionEnabled = true
        circleView.legend.enabled = false
        
        view.addSubview(circleView)
        
        let horizontalCenter = NSLayoutConstraint(item: circleView, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0)
        
        let verticalCenter = NSLayoutConstraint(item: circleView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.0, constant: 0)
        
        let width = NSLayoutConstraint(item: circleView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 400)
        
        let height = NSLayoutConstraint(item: circleView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 400)
        
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
                
        // updates category list if new category added
        handle = ref?.child(USER_PATH + "/active").observe(.childAdded, with: { (snapshot) in
            //get name of category
            let categoryName = snapshot.key
            self.timeOf[categoryName] = snapshot.value as? Int
            self.updateColor(category: categoryName)
        })
        
        // updates category list if new category deleted
        handle = ref?.child(USER_PATH + "/active").observe(.childRemoved, with: { (snapshot) in
            let categoryName = snapshot.key
            self.timeOf.removeValue(forKey: categoryName)
            self.colorOf.removeValue(forKey: categoryName)
            self.updateChart()
        })
        
        
        //updates when value changes in firebase
        handle = ref?.child(USER_PATH + "/active").observe(.childChanged, with: { (snapshot) in
            let categoryName = snapshot.key
            self.timeOf[categoryName] = snapshot.value as? Int
            self.updateChart()
        })
        
        // self.navigationController?.isNavigationBarHidden = true;
        
        let addTaskButton = UIBarButtonItem(title: "Add Task",
                                         style: .plain,
                                         target: self,
                                         action: #selector(HomeViewController.addButtonTapped))
        
        view.backgroundColor = .white
        self.navigationItem.rightBarButtonItem = addTaskButton
        
        fetchData()
        setupView()
        addButton()
        addLabel()
        
        selectedTaskName.text = "Select a task"
        
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: #selector(self.updateChart), userInfo: nil, repeats: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        fetchData()
        updateChart()
    }
    
    //===========================================================
    //           OBSERVERS
    //===========================================================
    @objc func appBecameActive() {
        if(balanceTimer.timeRemainingInTask <= 0) {
            taskFinished()
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
