//
//  RealmObjects.swift
//  balance
//
//  Created by Ben Sheppard on 4/2/19.
//  Copyright © 2019 Orb Mentality. All rights reserved.
//

import Foundation
import RealmSwift

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

class Task : Object {
    @objc dynamic var name : String? = nil // name of task
    var time = RealmOptional<Int>() // time of task
}


extension User {
    func writeToRealm() {
        try! uiRealm.write() {
            uiRealm.add(self)
        }
    }
}
// not currently being used---------------------------------^

// timer settings when exiting/entering app
class TimerStatus : Object {
    @objc dynamic var dateOnExit : Date? = nil
    let timerRunning = RealmOptional<Bool>()
}

class Tasks : Object {
    @objc dynamic var duration = 0
    @objc dynamic var name = ""
}

extension TimerStatus {
    func writeToRealm() {
        try! uiRealm.write() {
            uiRealm.add(self)
        }
    }
}

