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
    
    //cell is tapped
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //get current number of active minutes
        ref?.child("active").child(name).observeSingleEvent(of: .value, with: {(snapshot) in
            var newTime = snapshot.value! as! Int
            
            //adds selected number of active minutes to the total
            self.ref?.child("categories/" + self.path).child(self.tasks[indexPath.row])
                .observeSingleEvent(of: .value, with: {(snapshot) in
                let taskValue = snapshot.value! as! Int
                newTime += taskValue
                //adds total time to active list
                self.ref?.child("active").child(self.name).setValue(newTime)
                    
                //create reference to active tasks (stored in categories)
                self.ref?.child("categories").child(self.name).child("Active")
                        .child(self.tasks[indexPath.row]).setValue(taskValue)
            })
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath as IndexPath)
        cell.textLabel!.text = tasks[indexPath.row]
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
        ref?.child("categories").child(name).removeValue()
        ref?.child("active").child(name).removeValue()
        
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
    //delete task from database
    func deleteTask(task:String) {
        ref?.child("categories").child(path).child(task).removeValue()
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
        self.view.addSubview(tableView)
        
        //delete button
        let deleteButton = UIButton(type: .custom)
        let x_pos = width/2
        let y_pos = height - 70
        deleteButton.frame = CGRect(x: x_pos - 150, y: y_pos, width: 300, height:60)
        deleteButton.clipsToBounds = true
        deleteButton.setTitle("Delete Category", for: .normal)
        deleteButton.titleLabel?.font = UIFont(name:"Times New Roman", size: 30)
        deleteButton.setTitleColor(.red, for: .normal)
        deleteButton.backgroundColor = .white
        deleteButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        deleteButton.layer.cornerRadius = 10
        self.view.addSubview(deleteButton)
        
        //add button
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: (width/2) - 60, y: 3*height/4 - 60, width: 120, height: 120)
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.clipsToBounds = true
        
        button.setTitle("+", for: .normal)
        button.titleLabel?.font = UIFont(name:"Times New Roman", size: 80)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = color //current color
        button.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        self.view.addSubview(button)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let homeButton = UIBarButtonItem(title: "Home",
                                         style: .plain,
                                         target: self,
                                         action: #selector(TaskViewController.homeButtonTapped))
        homeButton.tintColor = .red
        self.navigationItem.rightBarButtonItem = homeButton
    
        ref = Database.database().reference()
        
        path = self.name + "/Tasks/"
        // updates tasks list if new tasks added
        handle = ref?.child("categories/" + path).observe(.childAdded, with: { (snapshot) in
            if let value = snapshot.value as? Int {
                let key = snapshot.key
                self.times[key] = value
                self.tasks.append(key)
                self.tableView.reloadData()
            }
        })
        //updates tasks list if tasks was deleted
        handle = ref?.child("categories/" + path).observe(.childRemoved, with: { (snapshot) in
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
