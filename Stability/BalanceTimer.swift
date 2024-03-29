//
//  BalanceTimer.swift
//  balance
//
//  Created by Ben Sheppard on 5/6/19.
//  Copyright © 2019 Orb Mentality. All rights reserved.
//

import Foundation
import RealmSwift

class BalanceTimer : Object {
    var hourStarted = 0
    var minuteStarted = 0
    var secondsCompleted = 0.0 // amount of gold
    var secondsInCategory = 0.0
    var tasksCompleted = 0
    
    var timeRemaining = 0 // time left in category
    var timeRemainingInTask = 0 // time left in task
    var categorySelected = "" // name of category
    var categoryStaged = "" // category to start
    var taskSelected = "" // task to start
    var taskTimer: Timer?
    var taskFinished = false
    var beforeOvertime = 0 // time of task before left app
    
    // -----------------------------FUNCTIONS----------------------------------
    @objc public func startScheduled() {
        if(timeRemaining == 0) {
            print("!!!!!!!ERROR!!!!!!!!!\n")
        }
        else {
            taskTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateScheduled), userInfo: nil, repeats: true)
            RunLoop.main.add(taskTimer!, forMode: RunLoop.Mode.common)
        }
    }
    @objc public func stopScheduled() -> Int {
        print("Timer done")
        taskTimer?.invalidate()
        print(timeRemaining)
        return timeRemaining
    }
    @objc public func updateScheduled() {
        secondsCompleted += 1
        secondsInCategory += 1
        timeRemaining -= 1
        timeRemainingInTask -= 1
    }
}
