//
//  ActiveCategories.swift
//  balance
//
//  Created by Ben Sheppard on 5/25/19.
//  Copyright © 2019 Orb Mentality. All rights reserved.
//

import Foundation
import RealmSwift

class ActiveCategories : Object {
    var timeOf = [String:Double]()
    
    func updateRunningCategory(category:String, duration:Int) {
        let currentTime = timeOf[category]
        timeOf[category] = (currentTime ?? 0) - Double(duration)
        if(timeOf[category] == 0) {
            balanceTimer.stopScheduled()
        }
        else if(timeOf[category]! < 0.0) {
            balanceTimer.stopScheduled()
            print("over by ", timeOf[category]!*(-1.0), " seconds.\n")
        }
    }
    
    func addTask(category:String, duration:Int) {
        let currentTime = timeOf[category]
        timeOf[category] = (currentTime ?? 0) + Double(duration)
    }
}
