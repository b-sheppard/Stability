//
//  CategoryViewController.swift
//  balance
//
//  Created by Ben Sheppard on 11/15/18.
//  Copyright © 2018 Orb Mentality. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase

class CategoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let white = UIColor(hex:15460841)
    let gray = UIColor(hex:5263695)
    
    //cell is tapped
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let dynamicView = DynamicTaskViewController()
        dynamicView.color = color
        dynamicView.taskName = tasks[indexPath.row]
        dynamicView.category = name
        navigationController?.pushViewController(dynamicView, animated: true)
        
        // fades out selection
        self.tableView.deselectRow(at: indexPath, animated: true)
        
        /*//adds selected number of active minutes to the total
        self.ref?.child(USER_PATH + "/categories/" + self.path).child(self.tasks[indexPath.row])
            .observeSingleEvent(of: .value, with: {(snapshot) in
            let taskValue = snapshot.value! as! Int
                
            //REALM
            let predicate = NSPredicate(format: "name = %@", self.name)
            let unscheduled = uirealm.objects(Category.self).filter("name = 'Unscheduled'").first
            let unscheduledTask = uirealm.objects(Task.self).filter("name = 'Unscheduled'").first
            let runningCategory = uirealm.objects(Category.self).filter(predicate).first
            var newCategoryTime = taskValue
                
            // add task to realm
            let Tpredicate = NSPredicate(format: "name = %@", self.tasks[indexPath.row])
            let doesExist = uirealm.objects(Task.self).filter(Tpredicate).first
            let newTask = Task()
            if(doesExist != nil) { print("Task already active") }
            else {
                newTask.category = self.name
                newTask.name = self.tasks[indexPath.row]
                newTask.duration = taskValue
             //   newTask.duration = 5
            }
                
            // edge case if timer isn't running
            if balanceTimer.categorySelected == "Unscheduled" {
                try! uirealm.write {
                    unscheduled!.duration = balanceTimer.timeRemaining
                    unscheduledTask!.duration = balanceTimer.timeRemainingInTask
                }
            }
                
            if unscheduled!.duration < taskValue {
                let alert = UIAlertController(title: "ERROR", message: "Not enough free time to add this task", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Fix Schedule", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            // category doesn't exist
            if(runningCategory == nil) {
                let categoryToAdd = Category()
                categoryToAdd.duration = newCategoryTime
                //categoryToAdd.duration = 5
                categoryToAdd.name = self.name
                categoryToAdd.color = self.color.rgb()!
                try! uirealm.write {
                    uirealm.add(categoryToAdd)
                    unscheduled!.duration -= newCategoryTime
                    unscheduledTask!.duration -= newCategoryTime
                    
                    //add task
                    uirealm.add(newTask)
                }
            }
            // category exists
            else {
                try! uirealm.write {
                    unscheduled!.duration -= newCategoryTime
                    unscheduledTask!.duration -= newCategoryTime
                    newCategoryTime += runningCategory!.duration
                    runningCategory!.duration = newCategoryTime
                    
                    // add task
                    uirealm.add(newTask)
                }
            }
            // edge case if timer isn't running
            if balanceTimer.categorySelected == "Unscheduled" {
                balanceTimer.timeRemaining = unscheduled!.duration
                balanceTimer.timeRemainingInTask = unscheduledTask!.duration
            }
        })*/
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath as IndexPath)
        cell.textLabel!.text = tasks[indexPath.row]
        cell.textLabel!.textColor = white
        cell.textLabel!.font = UIFont(name:"Futura", size: 30)
        cell.backgroundColor = color
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            //get tasks that will be deleted by swipe
            let toDelete = tasks[indexPath.row]
            deleteTask(task:toDelete)
            // handle delete (by removing the data from your array and updating the tableview)
        }
    }
    
    var name:String!
    var tasks:[String] = []
    var times : [String: Int] = [:]
    var path:String!
    var color:UIColor!
    
    let secondaryColor = UIColor.black.withAlphaComponent(0.4)
    
    var ref:DatabaseReference?
    var handle:DatabaseHandle?
    var tableView: UITableView!
    
    @objc func buttonTapped() {
        deleteCategory()
    }
    
    @objc func addButtonTapped() {
        addTaskView()
    }
    
    //deletes category from database
    func deleteCategory() {
        /*// removes potential time dependency if the task running is apart of the category (i'm lazy)
        if name == balanceTimer.categorySelected {
            let alert = UIAlertController(title: "Unable to delete category", message: "Category is currently running. Please stop category before deleting.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Continue", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
       */ ref?.child(USER_PATH).child("categories").child(name).removeValue()
        
        //delete active tasks
        let tasksPred = NSPredicate(format: "category = %@", self.name)
        let tasksToDelete = uirealm.objects(Task.self).filter(tasksPred)
        for task in tasksToDelete {
            task.deleteTask()
            
            if let rootViewController = navigationController?.viewControllers.first as? RootPageViewController {
                let homeViewController = rootViewController.viewControllerList[1] as? HomeViewController
                homeViewController?.fetchData()
            }
        }
        
        //delete category
        let predicate = NSPredicate(format: "name = %@", self.name)
        let categoryToDelete = uirealm.objects(Category.self).filter(predicate).first
        if categoryToDelete != nil {
            try! uirealm.write {
                uirealm.delete(categoryToDelete!)
            }
        }
        
        //delete total time from local data
        let totalTimeToDelete = uirealm.objects(TotalTime.self).filter(predicate).first
        try! uirealm.write {
            uirealm.delete(totalTimeToDelete!)
        }
        
        let savedTimes = uirealm.objects(TotalTime.self) // get total times
        totalTimes.removeAll() // avoids adding same category twice
        for time in savedTimes {
            if !totalTimes.contains(time) {
                totalTimes.append(time)
            }
        }        
        navigationController?.popViewController(animated: true)
    }
    
    //edit with info
    func editTaskView(snapshot: DataSnapshot) {
        //init
        let addTaskView = AddTaskViewController()
        
        //add the view as a child
        addTaskView.path = path
        addTaskView.color = color
        addTaskView.taskName = snapshot.key
        addTaskView.isOld = true
        
        self.addChild(addTaskView)
        self.view.addSubview(addTaskView.view)
        addTaskView.didMove(toParent: self)
    }
    
    //add new task with info
    func addTaskView() {
        //init view
        let addTaskView = AddTaskViewController()
        
        //add the view as a child
        addTaskView.path = path
        addTaskView.color = color
        
        self.addChild(addTaskView)
        self.view.addSubview(addTaskView.view)
        addTaskView.animShow()
        addTaskView.didMove(toParent: self)
    }
    //delete task from database
    func deleteTask(task:String) {
        ref?.child(USER_PATH + "/categories").child(path).child(task).removeValue()
    }
    
    func setupView() {
        //initial positions
        let screensize: CGRect = UIScreen.main.bounds
        let width = screensize.width
        let height = screensize.height
        
        self.view.frame = CGRect(x:0, y: 0, width: width, height: height)
        self.view.backgroundColor = color
        
        self.title = name
        
        tableView = UITableView(frame: CGRect(x: 0, y: 80, width: width, height: height/2))
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = color
        tableView.separatorColor = secondaryColor
        self.view.addSubview(tableView)
        
        //delete button
        let deleteButton = UIButton(type: .custom)
        let x_pos = width/2
        let y_pos = 85*height/100
        deleteButton.frame = CGRect(x: x_pos - 150, y: y_pos, width: 300, height:60)
        deleteButton.clipsToBounds = true
        deleteButton.setTitle("Delete Category", for: .normal)
        deleteButton.titleLabel?.font = UIFont(name:"Futura", size: 30)
        deleteButton.setTitleColor(.red, for: .normal)
        deleteButton.backgroundColor = white
        deleteButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        deleteButton.layer.cornerRadius = 10
        self.view.addSubview(deleteButton)
        
        //add button
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: (width/2) - 60, y: 3*height/4 - 60, width: 120, height: 120)
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.clipsToBounds = true
        
        button.setTitle("+", for: .normal)
        button.titleLabel?.font = UIFont(name:"Futura", size: 80)
        button.setTitleColor(secondaryColor, for: .normal)
        button.backgroundColor = color //current color
        button.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        self.view.addSubview(button)
        
    }
    override func viewDidAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.barTintColor = color
        navigationController?.setNavigationBarHidden(false, animated: false)

        ref = Database.database().reference()
        
        path = self.name + "/Tasks/"
        // updates tasks list if new tasks added
        handle = ref?.child(USER_PATH + "/categories/" + path).observe(.childAdded, with: { (snapshot) in
            if let value = snapshot.value as? Int {
                let key = snapshot.key
                self.times[key] = value
                self.tasks.append(key)
                self.tableView.reloadData()
            }
        })
        //updates tasks list if tasks was deleted
        handle = ref?.child(USER_PATH + "/categories/" + path).observe(.childRemoved, with: { (snapshot) in
            if (snapshot.value as? Int) != nil {
                let key = snapshot.key
                if let positionInTasks = self.tasks.firstIndex(of: key) {
                    self.tasks.remove(at: positionInTasks)
                    self.times.removeValue(forKey: key)

                    self.tableView.reloadData()
                }
            }
        })
        
        setupView()
    }
}
