//
//  Timer.swift
//  balance
//
//  Created by Ben Sheppard on 5/6/19.
//  Copyright © 2019 Orb Mentality. All rights reserved.
//

import Foundation
import RealmSwift

class Timer : Object {
    var timeRemaining = 10
    var categorySelected = "category"
    var taskSelected = "task"
    
    
    @objc public func buttonTapped() {
        print("test\n")
    }
}
