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


class HomeViewController: UIViewController, ChartViewDelegate, UIViewControllerTransitioningDelegate {
    let white = UIColor(hex:15460841)
    let gray = UIColor(hex:5263695)
    
    //database variables
    var ref:DatabaseReference?
    var handle:DatabaseHandle?
    var circleView: PieChartView!
    
    //color variables
    let gold = NSUIColor(hex: 15780864) //gold color
    
    //active category variables
    var categoryPosition: Dictionary = [String:String]()
    var timeOf: Dictionary = [String:Int]()
    var colorOf: Dictionary = [String:NSUIColor]()
    var selected = "Unscheduled"
    var mainButton: UIButton!
    var circleLayer: CAShapeLayer!
    var restartButton: UIButton!
    var selectedTaskName = UILabel()
    var descriptionLabel = UILabel()
    
    //timer variables
    var timer: Timer?
    
    var active_categories = [Category]()
    
    var resumeTapped = false
    
    //animation
    var didStop = true
    let transition = CircularTransition()
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .dismiss
        transition.startingPoint = mainButton.center
        transition.circleColor = white
        return transition
    }
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .present
        transition.startingPoint = mainButton.center
        transition.circleColor = presented.view.backgroundColor ?? .green
        return transition
    }

    //==========================================
    //          SCHEDULED TIMER
    //==========================================
    // starts animation of longpress
    @objc private func hold(gesture: UIGestureRecognizer) {
        if let longPress = gesture as? UILongPressGestureRecognizer {
            if longPress.state == UIGestureRecognizer.State.began && balanceTimer.categorySelected != "Unscheduled" {
                
                // ring wrap around
                let holdAnimation = CABasicAnimation(keyPath: "strokeEnd")
                holdAnimation.toValue = 1
                holdAnimation.duration = 1.5
                holdAnimation.fillMode = CAMediaTimingFillMode.forwards
                holdAnimation.isRemovedOnCompletion = false
                circleLayer.add(holdAnimation, forKey: "stroke")
                
                // get color of current task category
                let categoryPredicate = NSPredicate(format: "name = %@", balanceTimer.categorySelected)
                let categoryColor = uirealm.objects(Category.self).filter(categoryPredicate).first!.color
                // change color
                let colorAnimation = CABasicAnimation(keyPath: "strokeColor")
                colorAnimation.fromValue = NSUIColor(hex:categoryColor).cgColor
                colorAnimation.toValue = gold.cgColor
                colorAnimation.duration = 1.5
                circleLayer.add(colorAnimation, forKey: "strokeColor")
                
                let dummy = UIView()
                dummy.frame = CGRect(x: 0, y: 0, width: 0.001, height: 0.001)
                self.view.addSubview(dummy)
                dummy.backgroundColor = gray
                
                UIView.animate(withDuration: 1.5, delay: 0, animations: {
                    dummy.backgroundColor = self.white
                    self.mainButton.shrinkButton()
                }, completion: { _ in
                    if self.didStop {
                        self.longPress()
                    }
                    dummy.removeFromSuperview()
                    self.circleLayer.strokeEnd = 0
                    self.didStop = true // used so task isn't involuntarily deleted
                })
            }
            if longPress.state == UIGestureRecognizer.State.ended || longPress.state == UIGestureRecognizer.State.cancelled {
                self.didStop = false
                circleLayer.removeAllAnimations()
                self.mainButton.growButton()
            }
        }
    }
    
    // removes currently running task and adds time back to unscheduled
    @objc public func longPress() {
        didStop = true // used so task isn't involuntarily deleted
        descriptionLabel.textColor = white // makes help info invisible
        // finds currently running task and removes it
        if balanceTimer.categorySelected != "Unscheduled" {
            //update total time
            let tmp = totalTimes.filter({$0.name == balanceTimer.categorySelected}).first?.duration ?? 0
            try! uirealm.write {
                totalTimes.filter({$0.name == balanceTimer.categorySelected}).first?.duration = tmp + balanceTimer.secondsInCategory * 1.0/3600
            }
            
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
    
    // start a task if one is actually selected
    @objc public func startTapped() {
        mainButton.shrinkGrowButton()
        didStop = true // used so task isn't involuntarily deleted
        let checkStatus = uirealm.objects(TimerStatus.self).first
        if !checkStatus!.timerRunning && balanceTimer.categoryStaged != "" {
            mainButton.setTitle("STOP", for: .normal)
            descriptionLabel.textColor = gray

            //stop unscheduled timer
            balanceTimer.stopScheduled()
            
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
            
            balanceTimer.secondsInCategory = 0.0
            balanceTimer.categorySelected = newCategory!.name
            balanceTimer.timeRemaining = newCategory!.duration
            balanceTimer.taskSelected = newTask!.name
            balanceTimer.timeRemainingInTask = newTask!.duration
            balanceTimer.startScheduled()
            
        }
        else if checkStatus!.timerRunning {
            descriptionLabel.textColor = white

            mainButton.setTitle("START", for: .normal)
            balanceTimer.stopScheduled()

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
            
            //update total time
            let tmp = totalTimes.filter({$0.name == balanceTimer.categorySelected}).first?.duration ?? 0
            print(tmp)
            try! uirealm.write {
                totalTimes.filter({$0.name == balanceTimer.categorySelected}).first?.duration = tmp + balanceTimer.secondsInCategory * 1.0/3600
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
    //          CHART FUNCTIONS
    //==========================================
    
    // gets name of selected chart
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        let c = categoryPosition[String(Int(entry.x))]!
        goToCategory(category: c)
    }
    
    // go to add task view when unscheduled or completed sections of pie chart are tapped
    @objc func goToTaskView() {
        if let rootViewController = navigationController?.viewControllers.first as? RootPageViewController {
            let taskViewController = rootViewController.viewControllerList[2]
            rootViewController.setViewControllers([taskViewController], direction: .forward, animated: true, completion: nil)
        }
    }
    
    //goes to active tasks in category
    func goToCategory(category: String) {
        let categoryView = ActiveTaskViewController()
        categoryView.name = category
        
        //go to add task section if gray area is tapped
        if category == "Unscheduled" {
            goToTaskView()
        }
        //go to add task section if gold area is tapped
        else if category == "Completed" {
            goToTaskView()
        }
            
        else {
            //assign color to category
            let categoryPredicate = NSPredicate(format: "name = %@", category)
            let categoryColor = uirealm.objects(Category.self).filter(categoryPredicate).first!.color
            
            //go to list of active tasks
            categoryView.color = NSUIColor(hex: categoryColor)
            categoryView.transitioningDelegate = self
            categoryView.modalPresentationStyle = .custom
            navigationController?.present(categoryView, animated: true, completion: nil)
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
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
        
        //update total time
        let tmp = totalTimes.filter({$0.name == balanceTimer.categorySelected}).first?.duration ?? 0
        try! uirealm.write {
            totalTimes.filter({$0.name == balanceTimer.categorySelected}).first?.duration = tmp + Double(taskToDelete.duration) * 1.0/3600
        }
        
        // last task in category finished
        if balanceTimer.timeRemaining <= 0 {
            secondsOvertime = unscheduled.duration + balanceTimer.timeRemaining
            try! uirealm.write {
                checkStatus.timerRunning = false
                checkStatus.currentCategory = "Unscheduled"
                checkStatus.currentTask = "Unscheduled"
                uirealm.delete(categoryToDelete)
                uirealm.delete(taskToDelete)
            }
        }
        // not last task in category (keeps category)
        else if balanceTimer.timeRemainingInTask <= 0 {
            secondsOvertime = unscheduled.duration + balanceTimer.timeRemainingInTask
            
            try! uirealm.write {
                categoryToDelete.duration = categoryToDelete.duration - taskToDelete.duration
                checkStatus.timerRunning = false
                checkStatus.currentCategory = "Unscheduled"
                checkStatus.currentTask = "Unscheduled"
                uirealm.delete(taskToDelete)
            }
        }
        
        balanceTimer.secondsInCategory = 0.0
        balanceTimer.timeRemaining = secondsOvertime
        balanceTimer.timeRemainingInTask = secondsOvertime
        balanceTimer.categorySelected = "Unscheduled"
        balanceTimer.taskSelected = "Unscheduled"
        
        mainButton.setTitle("START", for: .normal)
        descriptionLabel.textColor = white
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
        balanceTimer.secondsInCategory = Double(timeInterval)
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
    
    // Displayed a keep going option when all tasks are complete
    // Could also be used as a restart in case something goes wrong
    func addRestartButton() {
        restartButton = UIButton()
        let screensize: CGRect = UIScreen.main.bounds
        restartButton.frame = CGRect(x: screensize.width/2, y: 50,
                                     width: screensize.width - 50, height: 80)
        restartButton.layer.cornerRadius = 5
        restartButton.center.x = screensize.width/2
        restartButton.setTitle("Add more tasks", for: .normal)
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

    // Notify user when current schedule is no longer possible
    func fixSchedule() {
        // schedule cannot be fixed
        if balanceTimer.secondsCompleted >= 86400 {
            timer?.invalidate()
            selectedTaskName.text = "You are a failure."
            selectedTaskName.textColor = white
            balanceTimer.stopScheduled()
            restartAllTimers()
            return
        }
        // gives user a chance to remove tasks and keep going
        else {
            timer?.invalidate()
            navigationController?.navigationBar.barTintColor = gray
            let scheduleFixer = FixScheduleView()
            navigationController?.pushViewController(scheduleFixer, animated: true)
        }
        
    }
    
    // main logic of how chart functions
    @objc func updateChart() {
        // timer is finished
        if balanceTimer.timeRemainingInTask < 0 {
            // no more unscheduled time
            if balanceTimer.categorySelected == "Unscheduled" {
                fixSchedule()
                return
            }
            // time in active task is finished
            else {
                taskFinished()
            }
        }
        // user finished all tasks: Display "balance achieved" (placeholder for now)
        if balanceTimer.tasksCompleted > 0 && active_categories.count == 1 {
            selectedTaskName.text = "All tasks finished!"
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

        // display all active categories on pie chart
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
                dataEntry.label = formatTimeRemaining(time: balanceTimer.timeRemaining)
            }
            else {
                 dataEntry.label = formatTimeRemaining(time: cat.duration)
            }
            // catches negative values of categories (shouldn't happen but what if)
            if cat.duration <= 0 {
                dataEntry.value = 0
            }
            // ensures tasks less than an hour are still large enough on pie chart to select
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
        completedEntry.label = formatTimeRemaining(time: Int(balanceTimer.secondsCompleted))
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
        circleView.data?.setDrawValues(false) // hides x values
        circleView.data?.setValueFont(UIFont(name:"Futura", size: 12)!)
        circleView.data?.setValueTextColor(white)
    }
    
    func formatTimeRemaining(time: Int) -> String {
        let hour = Int(time / 3600)
        let minutesLeft = time - 3600*hour
        let minute = Int(minutesLeft / 60)
        let seconds = minutesLeft - 60*minute
        return String(hour) + "h" + String(minute) + "m" + String(seconds) + "s"
    }
    // updates colors (name of category as key)
    func updateColor(category: String) {
        if category == "Unscheduled" {
            self.colorOf[category] = gray
            return
        }
        // get color of category from firebase
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
        
        // recognize a tap
        let tap = UITapGestureRecognizer(target: self, action: #selector(HomeViewController.startTapped))
        // recognize a press (function called after 3 seconds
        let hold = UILongPressGestureRecognizer(target: self, action: #selector(HomeViewController.hold(gesture:)))
        hold.minimumPressDuration = 0.5

        mainButton = UIButton(type: .custom)
        mainButton.frame = CGRect(x: 160, y: 100, width: 200, height: 200)
        mainButton.layer.cornerRadius = 0.5 * mainButton.bounds.size.width
        mainButton.clipsToBounds = true
        mainButton.translatesAutoresizingMaskIntoConstraints = false
        mainButton.addGestureRecognizer(tap)
        mainButton.addGestureRecognizer(hold)
        
        // for animation
        circleLayer = CAShapeLayer()
        let center = view.center
        let circularPath = UIBezierPath(arcCenter: center, radius: 100, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        circleLayer.path = circularPath.cgPath
        circleLayer.strokeColor = gold.cgColor
        circleLayer.lineWidth = 150
        circleLayer.strokeEnd = 0
        circleLayer.backgroundColor = white.cgColor
        circleLayer.fillColor = white.cgColor
        view.layer.addSublayer(circleLayer)
 
        // task has started
        if(checkStatus!.timerRunning) {
            mainButton.setTitle("STOP", for: .normal)
            descriptionLabel.textColor = gray
        }
        // task has stopped
        else {
            mainButton.setTitle("START", for: .normal)
            descriptionLabel.textColor = white

        }
        mainButton.titleLabel?.font = UIFont(name:"Futura", size: 60)
        mainButton.setTitleColor(gray, for: .normal)
        mainButton.backgroundColor = white
        
        view.addSubview(mainButton)
        
        // ensures button is at the center of screen for all devices
        let horizontalCenter = NSLayoutConstraint(item: mainButton!, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0)
        let verticalCenter = NSLayoutConstraint(item: mainButton!, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.0, constant: 0)
        let width = NSLayoutConstraint(item: mainButton!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 200)
        let height = NSLayoutConstraint(item: mainButton!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 200)
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
        descriptionLabel.frame = CGRect(x: screensize.width/2, y: 50, width: 300, height: 100)
        descriptionLabel.center.x = screensize.width/2
        descriptionLabel.center.y = screensize.height/8
        descriptionLabel.backgroundColor = white
        descriptionLabel.text = "Press and hold STOP \n for 2 seconds to finish task"
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        descriptionLabel.textColor = white
        descriptionLabel.adjustsFontSizeToFitWidth = true
        descriptionLabel.font = UIFont(name: "Futura", size: 20)
        
        view.addSubview(descriptionLabel)
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
        circleView.backgroundColor = white
        circleView.clipsToBounds = true
        circleView.translatesAutoresizingMaskIntoConstraints = false
        
        //settings on pie chart
        circleView.chartDescription?.enabled = false
        circleView.drawHoleEnabled = true
        circleView.holeRadiusPercent = 0.6
        circleView.holeColor = white
        circleView.rotationAngle = 0
        circleView.rotationEnabled = true
        circleView.isUserInteractionEnabled = true
        circleView.legend.enabled = false
        view.addSubview(circleView)
        
        // places circle in center for all devices
        let horizontalCenter = NSLayoutConstraint(item: circleView!, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0)
        let verticalCenter = NSLayoutConstraint(item: circleView!, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.0, constant: 0)
        let width = NSLayoutConstraint(item: circleView!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 350)
        let height = NSLayoutConstraint(item: circleView!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 350)
        let constraints: [NSLayoutConstraint] = [horizontalCenter, verticalCenter, width, height]
        NSLayoutConstraint.activate(constraints)
    
        self.circleView.delegate = self // used to add customization for circle
    }
    
    
    //==========================================
    //          OVERRIDE FUNCTIONS
    //==========================================
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        
        // update chart values when view is visible
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: #selector(self.updateChart), userInfo: nil, repeats: true)
        navigationController?.setToolbarHidden(true, animated: false)
        
        view.backgroundColor = white
        
        fetchData()
        setupView()
        addButton()
        addLabel()
        addDescription()
        
        selectedTaskName.text = "Select a Category"
    } // viewDidLoad()

    override func viewDidAppear(_ animated: Bool) {
        fetchData()
        updateChart()
        navigationController?.setNavigationBarHidden(true, animated: false)

    }
    
    // stop updating chart when the view dissapears
    override func viewDidDisappear(_ animated: Bool) {
        //timer?.invalidate()
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
