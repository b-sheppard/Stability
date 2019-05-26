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
    var secondsCompleted = 0.0
    
    var timeRemaining = 0
    var secondsRunning = 0
    var categorySelected = ""
    var categoryStaged = ""
    var taskSelected = ""
    var taskTimer: Timer?
    
    var categories = ActiveCategories()

    // FUNCTIONS----------------------------------
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
        if(timeRemaining == 0) {
            stopScheduled()
            print("OUT OF TIME")
        }
        secondsCompleted += 1
        secondsRunning += 1
        timeRemaining -= 1
    }
}
