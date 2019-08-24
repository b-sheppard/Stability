//
//  AppDelegate.swift
//  balance
//
//  Created by Ben Sheppard on 7/30/18.
//  Copyright © 2018 Orb Mentality. All rights reserved.
//

import UIKit
import CoreData
import Firebase
import FirebaseDatabase
import RealmSwift

var uirealm = try! Realm() // realm file
var balanceTimer = BalanceTimer() // custom timer
var USER_PATH = Auth.auth().currentUser?.uid ?? "error"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
                
        let mainNavigationController = MainNavigationController()
        mainNavigationController.title = "MainNG"
        
        
        //let mainViewController = MainViewController() //plus
        let loginViewController = LoginViewController()
        let rootViewController = RootPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        let launchedBefore = UserDefaults.standard.bool(forKey: "launchedBefore")
        
       // mainNavigationController.viewControllers = [mainViewController]
 
        //let rootViewController = RootPageViewController()
        if !launchedBefore {
            mainNavigationController.viewControllers = [rootViewController, loginViewController]
            UserDefaults.standard.set(true, forKey: "launchedBefore")
            
            let unscheduled = Category()
            let status = TimerStatus() // timer status
            
            //unscheduled.duration = 3680
            let curTime = Date()
            let calendar = Calendar.current
            balanceTimer.hourStarted = calendar.component(.hour, from: curTime)
            balanceTimer.minuteStarted = calendar.component(.minute, from: curTime)
            
            unscheduled.duration = 86400
            unscheduled.name = "Unscheduled"
            
            let unscheduledTask = Task()
            unscheduledTask.duration = unscheduled.duration
            unscheduledTask.name = unscheduled.name
            unscheduledTask.category = "Unscheduled"
            

            // REALM
            try! uirealm.write() {
                uirealm.add(status)
                uirealm.add(unscheduled)
                uirealm.add(unscheduledTask)
            }
        }
        else {
            mainNavigationController.viewControllers = [rootViewController, loginViewController]
        }
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()
        window?.rootViewController = mainNavigationController
        
        // removes shadow
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        UINavigationBar.appearance().tintColor = UIColor.black.withAlphaComponent(0.4)

        // font
        let attributes = [NSAttributedString.Key.font : UIFont(name: "Futura", size: 20)!, NSAttributedString.Key.foregroundColor : UIColor.black.withAlphaComponent(0.4)]
        UINavigationBar.appearance().titleTextAttributes = attributes
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        
        print("------------WRITING TO REALM------------\n")
        let checkStatus = uirealm.objects(TimerStatus.self).first
        
        let predicate = NSPredicate(format: "name = %@", balanceTimer.categorySelected)
        let runningCategory = uirealm.objects(Category.self).filter(predicate).first
        
        let taskPredicate = NSPredicate(format: "name = %@", balanceTimer.taskSelected)
        let runningTask = uirealm.objects(Task.self).filter(taskPredicate).first
        
        // Stop running timer (store time remaining in task)
        let date = Date()
        let secondsLeft = balanceTimer.stopScheduled()
        // keeps track of which timer is running
        var timerRunning = true
        if balanceTimer.categorySelected == "Unscheduled" {
            timerRunning = false
        }
        
        try! uirealm.write() {
            checkStatus?.secondsCompleted = Int(balanceTimer.secondsCompleted)
            checkStatus?.dateOnExit = date
            checkStatus?.timerRunning = timerRunning
            checkStatus?.currentCategory = balanceTimer.categorySelected
            checkStatus?.currentTask = balanceTimer.taskSelected
            checkStatus?.tasksCompleted = balanceTimer.tasksCompleted
            checkStatus?.hourStarted = balanceTimer.hourStarted
            checkStatus?.minuteStarted = balanceTimer.minuteStarted
            runningCategory!.duration = secondsLeft
            runningCategory!.name = balanceTimer.categorySelected
            runningTask!.duration = balanceTimer.timeRemainingInTask
            runningTask!.name = balanceTimer.taskSelected
        }

    }
/*
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
    }
*/
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("----------------ACTIVE-------------------\n")

        let checkStatus = uirealm.objects(TimerStatus.self).first
        
        let predicate = NSPredicate(format: "name = %@", checkStatus!.currentCategory)
        let runningCategory = uirealm.objects(Category.self).filter(predicate).first
        
        let taskPredicate = NSPredicate(format: "name = %@", checkStatus!.currentTask)
        var runningTask = uirealm.objects(Task.self).filter(taskPredicate).first
        
        let timeInactive = (checkStatus?.dateOnExit?.timeIntervalSinceNow ?? 0) * -1
        balanceTimer.secondsCompleted = Double(checkStatus?.secondsCompleted ?? 0) + timeInactive
        
        // category time
        balanceTimer.timeRemaining = runningCategory!.duration
        balanceTimer.categorySelected = runningCategory!.name
        balanceTimer.timeRemaining -= Int(timeInactive)
        
        // task time
        balanceTimer.timeRemainingInTask = runningTask!.duration
        balanceTimer.taskSelected = runningTask!.name
        balanceTimer.timeRemainingInTask -= Int(timeInactive)
        
        // num tasks completed
        balanceTimer.tasksCompleted = checkStatus!.tasksCompleted
        
        // start time of day
        if balanceTimer.hourStarted == 0 && balanceTimer.minuteStarted == 0 {
            balanceTimer.hourStarted = checkStatus!.hourStarted
            balanceTimer.minuteStarted = checkStatus!.minuteStarted
        }

        balanceTimer.startScheduled()
        //print(uirealm.objects(Category.self))
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        print("app will terminate..")
        
        
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "balance")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

