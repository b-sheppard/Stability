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

class ActiveTaskViewController: UIViewController,
        UITableViewDelegate, UITableViewDataSource {
    
    //cell is tapped
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        /*ref?.child(USER_PATH + "/selected").setValue(name)
        //adds selected task name to firebase
        ref?.child(USER_PATH + "/selectedTask").setValue(self.tasks[indexPath.row])
        ref?.child(USER_PATH + "/selectedTask").child("Name").setValue(self.tasks[indexPath.row])
        ref?.child(USER_PATH + "/selectedTask").child("Duration").setValue(self.times[tasks[indexPath.row]])
        */
        // REALM
        balanceTimer.categoryStaged = name
        balanceTimer.taskSelected = self.tasks[indexPath.row]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    //update cell rows
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //backup option
        let cell2 = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath as IndexPath)
        
        let cellIdentifier = "Cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? UITableViewCell
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCell.CellStyle.value2, reuseIdentifier: cellIdentifier)
        }
        cell?.textLabel!.text = tasks[indexPath.row]
        cell?.detailTextLabel?.text = String(times[tasks[indexPath.row]]!)
        cell?.accessoryType = .disclosureIndicator
        cell?.backgroundColor = color
        cell?.textLabel?.textColor = .white
        return cell ?? cell2
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            //get tasks that will be deleted by swipe
            let toDelete = tasks[indexPath.row]
            deleteTask(task:toDelete)
        }
    }
    
    var name:String!
    var tasks:[String] = []
    var times : [String: Int] = [:]
    var path:String!
    var color:UIColor!
    
    var ref:DatabaseReference?
    var handle:DatabaseHandle?
    var tableView: UITableView!
    
    @objc func homeButtonTapped() {
        let  vc =  self.navigationController?.viewControllers.filter({$0 is HomeViewController}).first
        
        self.navigationController?.popToViewController(vc!, animated: true)
    }
    //create right bar item
    let homeButton: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(title: "Add Task", style: .plain, target: self, action: #selector(homeButtonTapped))
        barButtonItem.tintColor = .red
        return barButtonItem
    }()
    
    @objc func buttonTapped() {
        deleteCategory()
    }
    
    @objc func addButtonTapped() {
        addTaskView()
    }
    
    //deletes category from database
    func deleteCategory() {
        ref?.child(USER_PATH + "/categories").child(name).removeValue()
        ref?.child(USER_PATH + "/active").child(name).removeValue()
        
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
        addTaskView.didMove(toParent: self)
    }
    //delete task from database (and subtract value from active
    func deleteTask(task:String) {
        //updates active times
        //deletes reference of active tasks
        //ref?.child(USER_PATH + "/categories").child(name).child("Active").child(task).removeValue()
        
        //print(uirealm.objects(Task.self))
        let Tpredicate = NSPredicate(format: "name = %@", task)
        let toDelete = uirealm.objects(Task.self).filter(Tpredicate).first!
        
        let unscheduled = uirealm.objects(Category.self).filter("name = 'Unscheduled'").first!
        let unscheduledTask = uirealm.objects(Task.self).filter("name = 'Unscheduled'").first!
        
        let Cpredicate = NSPredicate(format: "name = %@", toDelete.category)
        let category = uirealm.objects(Category.self).filter(Cpredicate).first
        let newTime = category!.duration - toDelete.duration
        
        //edge case if task is active
        if balanceTimer.categorySelected == "Unscheduled" {
            try! uirealm.write {
                unscheduled.duration = balanceTimer.timeRemaining
                unscheduledTask.duration = balanceTimer.timeRemaining
            }
        }
        print("add ", toDelete.duration)
        try! uirealm.write {
            category!.duration = newTime
            unscheduled.duration += toDelete.duration
            unscheduledTask.duration += toDelete.duration
            uirealm.delete(toDelete)
        }
        
        if balanceTimer.categorySelected == "Unscheduled" {
            balanceTimer.timeRemaining = unscheduled.duration
            balanceTimer.timeRemainingInTask = unscheduledTask.duration
        }
        
        fetchData()
        tableView.reloadData()
    }
    
    //destroy view
    @objc func CancelClicked() {
        self.navigationController?.isNavigationBarHidden = false
        print("cancel")
        self.view.removeFromSuperview()
        self.removeFromParent()
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
        tableView.separatorColor = UIColor.black.withAlphaComponent(0.4)
        self.view.addSubview(tableView)
        
        //create cancel button
        let cancelButton = UIButton(type: .custom)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.black, for: .normal)
        cancelButton.frame = CGRect(x: 10, y: 0, width: 60, height: 60)
        cancelButton.tintColor = .black
        cancelButton.addTarget(self, action: #selector(AddCategoryViewController.CancelClicked), for: .touchUpInside)
        cancelButton.tintColor = .black
        
        self.navigationController?.isNavigationBarHidden = false
        //self.view.addSubview(cancelButton)

    }
    
    func fetchData() {
        self.times.removeAll()
        self.tasks.removeAll()
        
        let predicate = NSPredicate(format: "category = %@", self.name)
        let activeTasks = uirealm.objects(Task.self).filter(predicate)
        
        for task in activeTasks {
            self.times[task.name] = task.duration
            self.tasks.append(task.name)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchData()
        //tableView.reloadData()

        /*
        ref = Database.database().reference()
        
        path = self.name + "/Active/"
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
        })*/
        setupView()
    }
}
