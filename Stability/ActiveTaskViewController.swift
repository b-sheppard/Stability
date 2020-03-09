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
    let white = UIColor(hex:15460841)
    let gray = UIColor(hex:5263695)
    
    //cell is tapped
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // REALM
        balanceTimer.categoryStaged = name
        balanceTimer.taskSelected = self.tasks[indexPath.row]
        exitView()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    //update cell rows
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //backup option
        let cell2 = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath as IndexPath)
        
        let cellIdentifier = "Cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCell.CellStyle.value1, reuseIdentifier: cellIdentifier)
        }
        let hour = Int(times[tasks[indexPath.row]]! / 3600)
        let minutesLeft = times[tasks[indexPath.row]]! - 3600*hour
        let minute = Int(minutesLeft / 60)
        let seconds = minutesLeft - 60*minute
        let timeString = String(hour) + "h " + String(minute) + "m " + String(seconds) + "s"
        
        cell?.textLabel!.text = tasks[indexPath.row]
        cell?.textLabel!.font = UIFont(name:"Futura", size: 30)
        cell?.detailTextLabel?.text = timeString
        cell?.detailTextLabel?.font = UIFont(name:"Futura", size:20)
        cell?.backgroundColor = color
        cell?.textLabel?.textColor = white
        cell?.detailTextLabel?.textColor = white
        
        // set selection color
        let selected = UIView()
        selected.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        cell?.selectedBackgroundView = selected
        
        return cell ?? cell2
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // delete option
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .default, title: "Remove") { action, indexPath in
            //get tasks that will be deleted by swipe
            let toDelete = self.tasks[indexPath.row]
            
            if toDelete != balanceTimer.taskSelected {
                self.deleteTask(task:toDelete)
            }
            else {
                let alert = UIAlertController(title: "Unable to delete task", message: "Task is currently running. Please stop task before deleting.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Continue", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
        
        delete.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        return [delete]
    }
    
    // i think this is not needed...
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            //get tasks that will be deleted by swipe
            let toDelete = tasks[indexPath.row]
            
            if toDelete != balanceTimer.taskSelected {
                deleteTask(task:toDelete)
            }
            else {
                let alert = UIAlertController(title: "Unable to delete task", message: "Task is currently running. Please stop task before deleting.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Continue", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
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
    var descriptionLabel = UILabel()
    
    @objc func exitView() {
        self.dismiss(animated: true, completion: nil)
    }
    
    //delete task from database (and subtract value from active)
    func deleteTask(task:String) {
        let Tpredicate = NSPredicate(format: "name = %@", task)
        let toDelete = uirealm.objects(Task.self).filter(Tpredicate).first!
        
        toDelete.deleteTask()

        fetchData()
        tableView.reloadData()
        if task.count == 0 {
            exitView()
        }
    }
    
    func addDescription() {
        let screensize: CGRect = UIScreen.main.bounds
        descriptionLabel.frame = CGRect(x: screensize.width/2, y: screensize.height,
                                   width: screensize.width, height: 200)
        descriptionLabel.center.x = screensize.width/2
        descriptionLabel.center.y = 3*screensize.height/4
        descriptionLabel.backgroundColor = color
        descriptionLabel.numberOfLines = 0
        descriptionLabel.text = "Tap a task to make active\nthen go back and press START"
        descriptionLabel.textAlignment = .center
        descriptionLabel.textColor = white
        descriptionLabel.font = UIFont(name: "Futura", size: 20)
        
        self.view.addSubview(descriptionLabel)
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
        tableView.rowHeight = 80
        self.view.addSubview(tableView)
        
        //add cancel button
        let cancelButton = UIButton()
        cancelButton.frame = CGRect(x: 0, y: 30, width: width/4, height: 60)
        cancelButton.clipsToBounds = true
        cancelButton.setTitle("Close", for: .normal)
        cancelButton.titleLabel?.font = UIFont(name:"Futura", size: 18)
        cancelButton.setTitleColor(UIColor.black.withAlphaComponent(0.4), for: .normal)
        cancelButton.setTitleColor(UIColor.black.withAlphaComponent(0.6), for: .highlighted)
        cancelButton.addTarget(self, action: #selector(exitView), for: .touchUpInside)
        self.view.addSubview(cancelButton)
        
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
        if let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
            if let rootViewController = navigationController.viewControllers.first as? RootPageViewController {
                let homeViewController = rootViewController.viewControllerList[1] as? HomeViewController
                homeViewController?.fetchData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        fetchData()
        setupView()
        addDescription()
    }
}
