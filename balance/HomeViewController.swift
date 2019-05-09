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
    let dayInSeconds = 86400.0 //seconds in 24 hours
 //   let dayInSeconds = 3600.0
    var secondsCompleted: Int = 0
    var passedSeconds: Int = 0
    var seconds: Int = 0
    var secondsLeftInTask: Int = 0
    var taskTimer: Timer?
    var unscheduledTimer: Timer? //used for unscheduled time
    var startDate: Date?
    var quitDate: Date?
    
    //These will be used to make sure only one timer is created at a time.
    var isTimerRunning: Bool = false
    
    var resumeTapped = false
    
    
    //==========================================
    //          SCHEDULED TIMER
    //==========================================
    @objc public func startTapped() {
        print("test")
    }
    /*
    //ensures that there is a task is selected
    func shouldStartTimer(category: String) {
        if category != "" {
            print("is timer running: ", isTimerRunning)
            if isTimerRunning == true {
                print("stop timer")
                mainButton.setTitle("Start", for: .normal)
                stopTimer()
            } else {
                stopUnscheduledTimer()
                mainButton.setTitle("Stop", for: .normal)
                startTimer()
            }
        } else {
            print("no task selected!")
        }
    }
    
    //Stops the activity and saves to Firebase
    func stopTimer() {
        invalidateTimer()
        isTimerRunning = false
        //start unscheduledTimer
        startUnscheduledTimer()
        
        //save locally
        ref?.child("active").child(selected).setValue(seconds)
        ref?.child("categories").child(selected).child("Active").child(selectedTaskName.text!).setValue(secondsLeftInTask)
        selectedTaskName.text = "Select a task"
    }
    
    //Starts new time with task
    func startTimer() {
        startDate = Date()
        
        //get seconds from firebase
        ref?.child("active").child(selected).observeSingleEvent(of: .value, with: {(snapshot) in
            print("value ", snapshot.value!)
            self.seconds = snapshot.value! as! Int
        })
        //get time left to complete individual task
        ref?.child("selectedTask").child("Duration").observeSingleEvent(of: .value, with: {(snapshot) in
            let timeLeftInTask = snapshot.value! as! Int
            self.secondsLeftInTask = timeLeftInTask
        })
        invalidateTimer()
        runTimer()
        
        isTimerRunning = true
        UserDefaults.standard.set(isTimerRunning,
                                  forKey:"quitTimerRunning")
    }
    
    func runTimer() {
        taskTimer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: #selector(self.updateTimer), userInfo: nil, repeats: true)
    }
    
    //ensures a non-running timer isn't invalidated
    func invalidateTimer() {
        if let timer = taskTimer {
            timer.invalidate()
        }
        if let timer2 = unscheduledTimer {
            timer2.invalidate()
        }
    }
    
    @objc func updateTimer() {
        if(secondsLeftInTask <= 0 ||
            seconds <= 0) {
            print("time has reached 0")
            stopTimer()
        }
        else {
            seconds -= 1     //This will decrement(count down)the seconds
            secondsCompleted += 1 //This will keep track of total completed seconds
            secondsLeftInTask -= 1
            timeOf[selected] = seconds
            updateChart()
        }
    }
    
    */
    
    //==========================================
    //          BUTTON FUNCTIONS
    //==========================================

    //center button TAPPED
    @objc func buttonTapped() {
        ref?.child(USER_PATH + "/selected").observeSingleEvent(of: .value, with: { (snapshot) in
            self.selected = snapshot.value! as! String
        })
    }
    
    @objc func addButtonTapped() {
        print("Go to Task")
        let taskViewController = TaskViewController()
        navigationController?.pushViewController(taskViewController, animated: true)
    }
    
    
    
    //==========================================
    //          CHART FUNCTIONS
    //==========================================
    //gets name of seleved chart
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
    
    func updateChart() {
        var categories : [PieChartDataEntry] = Array()
        let currentCategories = Array(timeOf.values)
        let currentCategoryNames = Array(timeOf.keys)
        
        var totalTime = 0.0 // used to calculate unscheduled time
        
        //get times of categories
        var position = 0
        for time in currentCategories {
            //add time entry to pie chart
            let dataEntry = PieChartDataEntry(value: Double(time), label: nil)
            dataEntry.x = Double(position)
            categories.append(dataEntry)
            
            //keep track of position
            let categoryName = currentCategoryNames[position]
            categoryPosition[String(position)] = categoryName
            position += 1
            
            //add to total time
            totalTime += Double(time)
        }
        
        //create unscheduled time
        //dayInSeconds - (totalTime + secondsCompleted) is used to factor in time ticked away from active categories
        let unscheduledEntry = PieChartDataEntry(value: dayInSeconds - (totalTime + Double(secondsCompleted)), label: nil)
        //let unscheduledEntry = PieChartDataEntry(value: Double(240), label: nil) //placeholder
        unscheduledEntry.x = Double(position)
        categories.append(unscheduledEntry)
        categoryPosition[String(position)] = "Unscheduled"
        position += 1
        
        //create completed time placeholder
        let completedEntry = PieChartDataEntry(value: Double(secondsCompleted), label: nil)
        completedEntry.x = Double(position)
        categories.append(completedEntry)
        categoryPosition[String(position)] = "Completed"
        
        let chartDataSet = PieChartDataSet(entries: categories, label: nil)
        let chartData = PieChartData(dataSet: chartDataSet)

        var categoryColor : [NSUIColor] = []

        //get colors of categories
        for category in currentCategoryNames {
            let currentColor = colorOf[category]
            categoryColor.append(currentColor!)
        }
        
        categoryColor.append(gray)
        categoryColor.append(gold)
        
        let final = categoryColor
        
        chartDataSet.colors = final
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
        mainButton = UIButton(type: .custom)
        mainButton.frame = CGRect(x: 160, y: 100, width: 200, height: 200)
        mainButton.layer.cornerRadius = 0.5 * mainButton.bounds.size.width
        mainButton.clipsToBounds = true
        mainButton.translatesAutoresizingMaskIntoConstraints = false
        
        mainButton.addTarget(self, action: #selector(HomeViewController.startTapped), for: .touchUpInside)
        mainButton.setTitle("Start", for: .normal)
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
        
        addObservers()
        
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
        
        setupView()
        addButton()
        addLabel()
        
        selectedTaskName.text = "Select a task"
    }

    override func viewDidAppear(_ animated: Bool) {
        updateChart()
    }
    
    
    /*
    func restartTimer() {
        // check if task timer was running
        isTimerRunning = (UserDefaults.standard.object(forKey: "isTimerRunning") != nil)
        
        let passedSeconds = UserDefaults.standard.integer(forKey: "secondsInBackground")
        self.seconds -= passedSeconds
        self.secondsCompleted += passedSeconds
        
        updateChart()
        
        // restart task timer
        if(isTimerRunning) {
            startTimer()
        }
        else {
            startUnscheduledTimer() //restart freetime timer
        }
    }*/
    
    
    
    
    //===========================================================
    //           OBSERVERS
    //===========================================================
    
    
    @objc func appLoadedFromBackground() {
        print("=============== APP LOADED FROM BACKGROUND ================")
        //let hasCompletedTutorial = UserDefaults.standard.object(forKey: "hasCompletedTutorial")

    }
    
    @objc func appGoesIntoBackground() {
        quitDate = Date()
        
        UserDefaults.standard.set(isTimerRunning, forKey: "isTimerRunning")
        
    }
    
    @objc func appBecameActive() {
        print("============= APP BECAME ACTIVE ==============")
    }
    
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(appGoesIntoBackground),
                                               name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appLoadedFromBackground),
                                               name: UIApplication.willEnterForegroundNotification, object: nil)
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
