//
//  DetailViewController.swift
//  balance
//
//  Created by Ben Sheppard on 9/21/18.
//  Copyright © 2018 Orb Mentality. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase
import RealmSwift
import SearchTextField

class TaskViewController: UIViewController {
    
    let white = UIColor(hex:15460841)
    let gray = UIColor(hex:5263695)
    let darkGray = UIColor()
    
    let MAX_CATEGORIES = 9;
    var categoryNames:[String] = ["+"]
    var categoryColors:[Int] = [colors[7]]
    var scrollView: UIScrollView!
    var taskSearchField: SearchTextField!
    var tasks = [Task]()
    var taskNames = [String]()
    var catColors = [String:Int]() // used in searchfield
    
    var ref:DatabaseReference?
    var handle:DatabaseHandle?
    var scrollViewAdded = false

    // add new category
    @objc public func buttonTapped(sender: UIButton) {
        //title
        guard let type = sender.currentTitle else {
            print("nowhere to go")
            return
        }
        //color
        guard let color = sender.backgroundColor else {
            print("no color to choose from")
            return
        }
        if type == "+" {
            addCategoryView()
        }
        else {
            categoryView(type:type, color: color)
        }
    } // buttonTapped()
    
    //create up category view
    func addCategoryView() {
        //init view
        let addCategoryViewController = AddCategoryViewController()
        
        //add the view as a child
        self.addChild(addCategoryViewController)
        self.view.addSubview(addCategoryViewController.view)
        addCategoryViewController.animShow()
        addCategoryViewController.didMove(toParent: self)
    } // addCategoryView
    
    //go to category view
    func categoryView(type:String, color: UIColor) {
        //init view
        let categoryView = CategoryViewController()
        categoryView.name = type
        categoryView.color = color
        
        navigationController?.pushViewController(categoryView, animated: true)
    } // categoryView()
    
    //create scroll view and buttons
    func createScrollView() {
        
        let screensize: CGRect = UIScreen.main.bounds
        let screenWidth = screensize.width
        let screenHeight = screensize.height
        let scrollWidth = screenWidth
        let scrollHeight = 2.75*screenHeight/8
        
        scrollView = UIScrollView(frame: CGRect(x: 0, y: 2*screenHeight/8, width: scrollWidth, height: 3*scrollHeight/2))
        scrollView.isScrollEnabled = true
        scrollView.isUserInteractionEnabled = true
        scrollView.backgroundColor = white
        scrollView.showsHorizontalScrollIndicator = true;
        scrollView.showsVerticalScrollIndicator = true;
        
        scrollView.contentSize = CGSize(width: scrollWidth, height: scrollHeight * 2)
        
        //add category buttons
        var col = 0
        var row:CGFloat = 1
        var buttonCount = 0
        for category in categoryNames {
            if col % 3 == 0 && col != 0 {
                row += 2
            }
            let button = UIButton(type: .custom)
            let x_pos = (7 + CGFloat(col % 3)*scrollWidth/3)
            let y_pos = (row)*scrollHeight/4 - 5
            button.frame = CGRect(x: x_pos, y: y_pos - 50, width: 110, height: 110)
            button.layer.cornerRadius = 0.5 * button.bounds.size.width
            button.clipsToBounds = true
            
            // adds add category button at the end of the list
            if category == "+" {
                button.setTitle(category, for: .normal)
                button.titleLabel?.font = UIFont(name:"Futura", size: 80)
                button.setTitleColor(gray, for: .normal)
                button.backgroundColor = white //gray
                button.addTarget(self, action: #selector(buttonTapped(sender:)), for: .touchUpInside)
            }
            // adds all other categories
            else {
                button.setTitle(category, for: .normal)
                button.titleLabel?.font = UIFont(name:"Futura", size: 30)
                button.setTitleColor(UIColor.black.withAlphaComponent(0.6), for: .normal)
                // fit button title to size
                button.titleLabel?.adjustsFontSizeToFitWidth = true
                button.titleLabel?.numberOfLines = 1
                button.titleLabel?.minimumScaleFactor = 0.1
                button.clipsToBounds = true
                //button color
                let buttonColor = UIColor(hex: categoryColors[buttonCount])
                button.backgroundColor = buttonColor
                button.addTarget(self, action: #selector(buttonTapped(sender:)), for: .touchUpInside)
            }
 
            self.scrollView.addSubview(button)
            col += 1
            buttonCount += 1
        }
        // insert view behind addCategoryView
        view.insertSubview(scrollView, at: 0)
        
        
    } // createScrollView()
    
    //create newTask textfield and keyboard
    func setupSearchField() {
        let screensize: CGRect = UIScreen.main.bounds
        let screenWidth = screensize.width
        let screenHeight = screensize.height
        
        taskSearchField = SearchTextField(frame: CGRect(x: 20, y: screenHeight/10 + 20, width: screenWidth - 40, height: 60))
        taskSearchField.backgroundColor = .white
        taskSearchField.borderStyle = .roundedRect
        taskSearchField.font = UIFont(name: "Futura", size: 25)
        taskSearchField.textColor = gray
        taskSearchField.keyboardAppearance = .dark
        taskSearchField.inlineMode = true
        taskSearchField.attributedPlaceholder = NSAttributedString(string: "Search For a Task...", attributes: [NSAttributedString.Key.foregroundColor : UIColor.gray.withAlphaComponent(0.5)])

        
        // autocompletes search
        taskSearchField.itemSelectionHandler = {filteredResults, itemPosition in
            let item = filteredResults[itemPosition]
            self.taskSearchField.text = item.title
            self.addTask(taskName:self.taskSearchField.text!)
            self.taskSearchField.text = ""
        }
        view.addSubview(taskSearchField)
    }
    
    // add task from search to realm
    func addTask(taskName:String) {
        let taskPos = taskNames.firstIndex(of: taskName)!
        let task = tasks[taskPos]
        let categoryName = task.category
        let taskValue = task.duration
        let taskName = task.name
        
        let predicate = NSPredicate(format: "name = %@", categoryName)
        let unscheduled = uirealm.objects(Category.self).filter("name = 'Unscheduled'").first
        let unscheduledTask = uirealm.objects(Task.self).filter("name = 'Unscheduled'").first
        let runningCategory = uirealm.objects(Category.self).filter(predicate).first
        var newCategoryTime = taskValue
        
        // add task to realm
        let Tpredicate = NSPredicate(format: "name = %@", taskName)
        let doesExist = uirealm.objects(Task.self).filter(Tpredicate).first
        let newTask = Task()
        
        // shake view if task already added
        if doesExist != nil {
            shakeTextField()
            return
        }
        else {
            newTask.category = categoryName
            newTask.name = taskName
            newTask.duration = taskValue
        }
        
        // edge case if timer isn't running
        if balanceTimer.categorySelected == "Unscheduled" {
            try! uirealm.write {
                unscheduled!.duration = balanceTimer.timeRemaining
                unscheduledTask!.duration = balanceTimer.timeRemainingInTask
            }
        }
        
        if unscheduled!.duration < taskValue {
            let alert = UIAlertController(title: "Unable to add task", message: "Not enough time available", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Continue", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            self.taskSearchField.text = ""
            shakeTextField()
            return
        }
        
        // category doesn't exist
        if(runningCategory == nil) {
            let categoryToAdd = Category()
            categoryToAdd.duration = newCategoryTime
            //categoryToAdd.duration = 5
            categoryToAdd.name = categoryName
            categoryToAdd.color = catColors[categoryToAdd.name]!
            try! uirealm.write {
                uirealm.add(categoryToAdd)
                unscheduled!.duration -= newCategoryTime
                unscheduledTask!.duration -= newCategoryTime
                
                //add task
                uirealm.add(newTask)
            }
        }
            // category exists
        else {
            try! uirealm.write {
                unscheduled!.duration -= newCategoryTime
                unscheduledTask!.duration -= newCategoryTime
                newCategoryTime += runningCategory!.duration
                runningCategory!.duration = newCategoryTime
                
                // add task
                uirealm.add(newTask)
            }
        }
        // edge case if timer isn't running
        if balanceTimer.categorySelected == "Unscheduled" {
            balanceTimer.timeRemaining = unscheduled!.duration
            balanceTimer.timeRemainingInTask = unscheduledTask!.duration
        }
    }
    
    func shakeTextField() {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.1
        animation.repeatCount = 4
        animation.fromValue = NSValue(cgPoint: CGPoint(x: taskSearchField.center.x - 5,
                                                       y: taskSearchField.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: taskSearchField.center.x + 5,
                                                     y: taskSearchField.center.y))
        
        taskSearchField.layer.add(animation, forKey: "position")
    }
    //fetches all tasks from firebase
    func fetchData() {
        //adds task data to an array
        taskNames.removeAll()
        ref?.child(USER_PATH + "/categories").observeSingleEvent(of: .value, with: { (snapshot) in
            for case let category as DataSnapshot in snapshot.children {
                let cat = category.childSnapshot(forPath: "Tasks") as DataSnapshot
                let catName = category.childSnapshot(forPath: "Name").value as! String
                let catColor = category.childSnapshot(forPath: "Color").value as! Int
                self.catColors[catName] = catColor
                for case let tasksInCategory as DataSnapshot in cat.children {
                    let toAdd = Task()
                    toAdd.category = catName 
                    toAdd.duration = tasksInCategory.value as! Int
                    toAdd.name = tasksInCategory.key 
                    self.tasks.append(toAdd)
                    self.taskNames.append(toAdd.name)
                    self.taskSearchField.filterStrings(self.taskNames)
                }
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        fetchData()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        fetchData()
        createScrollView()
        
        // updates category list if new category added
        handle = ref?.child(USER_PATH + "/categories").observe(.childAdded, with: { (snapshot) in
            if let item = snapshot.childSnapshot(forPath: "/Name").value as? String {
                self.categoryNames.insert(item, at: 0)
                
            }
            if let color = snapshot.childSnapshot(forPath: "/Color").value as? Int {
                self.categoryColors.insert(color, at: 0)
            }
            self.scrollView.removeFromSuperview()
            self.createScrollView()
        })
        
        // updates category list if category removed
        handle = ref?.child(USER_PATH + "/categories").observe(.childRemoved, with: { (snapshot) in
            if let item = snapshot.childSnapshot(forPath: "/Name").value as? String {
                if let position = self.categoryNames.firstIndex(of: item) {
                    self.categoryNames.remove(at: position)
                    self.categoryColors.remove(at: position)
                    print(item + " category removed")
                }
                self.scrollView.removeFromSuperview()
                self.createScrollView()
            }
        })

        view.backgroundColor = white

        self.hideKeyboardWhenTappedAround()
        self.setupSearchField()
    } // viewDidLoad()
} // class TaskViewController()
