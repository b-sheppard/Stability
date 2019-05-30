//
//  RealmObjects.swift
//  balance
//
//  Created by Ben Sheppard on 4/2/19.
//  Copyright © 2019 Orb Mentality. All rights reserved.
//

import Foundation
import RealmSwift
/*
// not currently being used---------------------------------
class User : Object {
    var categories = List<Category>() // collection of categories
    @objc dynamic var selected : String? = nil // selected task
    var active = List<Task>() // total times
}

class Category : Object {
    @objc dynamic var name : String? = nil // name of category
    var tasks = List<Task>() // collection of tasks
    var active = List<Task>() // times of active tasks
    var color = RealmOptional<Int>() // color of category

}

class Tasks : Object {
    @objc dynamic var name : String? = nil // name of task
    var time = RealmOptional<Int>() // time of task
}*/

// not currently being used---------------------------------^

// timer settings when exiting/entering app
class TimerStatus : Object {
    @objc dynamic var dateOnExit : Date? = nil
    @objc dynamic var timerRunning = false
    @objc dynamic var secondsCompleted = 0
    @objc dynamic var currentCategory = "Unscheduled"
    @objc dynamic var currentTask = "Unscheduled"
    @objc dynamic var tasksCompleted = 0
}

class Task : Object {
    @objc dynamic var duration = 0
    @objc dynamic var name = ""
    @objc dynamic var category = ""
}

class Category : Object {
    @objc dynamic var duration = 0
    @objc dynamic var name = ""
    @objc dynamic var color = 0
}

extension Task {
    func deleteTask() {
        balanceTimer.stopScheduled()
        let unscheduled = uirealm.objects(Category.self).filter("name = 'Unscheduled'").first!
        let unscheduledTask = uirealm.objects(Task.self).filter("name = 'Unscheduled'").first!
        
        let Cpredicate = NSPredicate(format: "name = %@", self.category)
        let category = uirealm.objects(Category.self).filter(Cpredicate).first
        let newTime = category!.duration - self.duration
        
        //edge case if task is active
        if balanceTimer.categorySelected == "Unscheduled" {
            try! uirealm.write {
                unscheduled.duration = balanceTimer.timeRemaining
                unscheduledTask.duration = balanceTimer.timeRemaining
            }
        }
        if newTime == 0 {
            try! uirealm.write {
                unscheduled.duration += self.duration
                unscheduledTask.duration += self.duration
                uirealm.delete(category!)
                uirealm.delete(self)
            }
        }
        else {
            try! uirealm.write {
                category!.duration = newTime
                unscheduled.duration += self.duration
                unscheduledTask.duration += self.duration
                uirealm.delete(self)
            }
        }
        
        balanceTimer.timeRemaining = unscheduled.duration
        balanceTimer.timeRemainingInTask = unscheduledTask.duration
        balanceTimer.categoryStaged = ""
        balanceTimer.categorySelected = "Unscheduled"
        balanceTimer.taskSelected = "Unscheduled"
        balanceTimer.startScheduled()
    }
}
