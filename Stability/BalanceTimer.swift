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
    var secondsCompleted = 0.0
    var tasksCompleted = 0
    
    var timeRemaining = 0 // time left in category
    var timeRemainingInTask = 0 // time left in task
    var categorySelected = "" // name of category
    var categoryStaged = "" // category to start
    var taskSelected = "" // task to start
    var taskTimer: Timer?
    var taskFinished = false
    
    // -----------------------------FUNCTIONS----------------------------------
    @objc public func startScheduled() {
        if(timeRemaining == 0) {
            print("!!!!!!!ERROR!!!!!!!!!\n")
        }
        else {
            taskTimer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: #selector(self.updateScheduled), userInfo: nil, repeats: true)
        }
    }
    @objc public func stopScheduled() -> Int {
        print("Timer done")
        taskTimer?.invalidate()
        return timeRemaining
    }
    @objc public func updateScheduled() {
        secondsCompleted += 1
        timeRemaining -= 1
        timeRemainingInTask -= 1
    }
}
