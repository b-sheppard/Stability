//
//  scratch.swift
//  balance
//
//  Created by Ben Sheppard on 4/4/19.
//  Copyright © 2019 Orb Mentality. All rights reserved.
//

import Foundation
import Firebase
import RealmSwift

/*let colors = [
 r255 g60 b70,
 r60 g180 b255,
 r200 g130 b250,
 r255 g155 b200,
 r162 g168 b176,
 r255 g255 b80,
 r155 g80 b245
 ]
 16727110
 3978495
 13140730
 16751560
 10660016
 16777040
 10178805
 
*/
/*
func updateLocalDatabase() {
    let ref = Database.database().reference()
    // collects data from Firebase
    ref.child("Users").observeSingleEvent(of:.value, with: { (snapshot) in
        let user = User()
        // gets active category times
        if let active = snapshot.childSnapshot(forPath: "/active").value as?
            [String : RealmOptional<Int>] {
            for task in active {
                let t = Task()
                t.name = task.key
                t.time = task.value
                print(task.key)
                print(task.value)
                user.active.append(t)
            }
        }
        // gets category information (may not be necessary)
        let categories = snapshot.childSnapshot(forPath: "/categories")
        // loops through each category
        for category in categories.children.allObjects as! [DataSnapshot] {
            let cat = Category()
            guard let dictionary = category.value as? [String : AnyObject] else { return }
            if let active = dictionary["Active"] as? Dictionary<String, Int> {
                cat.active = active
            }
            cat.color = (dictionary["Color"] as! Int)
            let name = dictionary["Name"] as! String
            cat.name = name
            
            if let tasks = dictionary["Tasks"] as? Dictionary<String, Int> {
                cat.tasks = tasks
            }
            user.categories[name] = cat
        }
        // gets selected information
        if let selected = snapshot.childSnapshot(forPath: "/selected").value as?
            String { user.selected = selected }
        user.writeToRealm()
    })
}
*/