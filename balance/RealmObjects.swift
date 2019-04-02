//
//  RealmObjects.swift
//  balance
//
//  Created by Ben Sheppard on 4/2/19.
//  Copyright © 2019 Orb Mentality. All rights reserved.
//

import Foundation
import RealmSwift

class User : Object {
    @objc dynamic var categories = [Category]()
    @objc dynamic var selected : String? = nil
    @objc dynamic var active = Dictionary<String, Int>() // total times
}

class Category : Object {
    @objc dynamic var name : String? = nil
    @objc dynamic var tasks = Dictionary<String, Int>()
    @objc dynamic var active = Dictionary<String, Int>() // times of individual tasks
    var color = RealmOptional<Int>()

}

extension User {
    func writeToRealm() {
        try! uiRealm.write() {
            uiRealm.add(self)
        }
    }
}


