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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        
        let mainNavigationController = MainNavigationController()
        mainNavigationController.title = "MainNG"
        
        
        
        
        let mainViewController = TaskViewController() //task
    //    let mainViewController = MainViewController() //plus button
        
        
        
        
        
        //mainViewController.title = "ADD A TASK"
        
       // mainNavigationController.viewControllers = [mainViewController]
 
        let homeViewController = HomeViewController()
        mainNavigationController.viewControllers = [homeViewController, mainViewController]        
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()
        window?.rootViewController = mainNavigationController
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        
        //done
        print("application will resign active...")
        //set the time of exiting app to calculate time it was in background later
        let currentDate = Date()
        UserDefaults.standard.set(currentDate as Date, forKey:"quitDate")

    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("did enter background app goes in.")
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "AppDidEnterBackground"), object: nil)
        let quitTimerRunning =
            UserDefaults.standard.bool(forKey: "quitTimerRunning")
        
        let currentDate = Date()
        UserDefaults.standard.set(currentDate as Date, forKey:"quitDate")
        
        print("quitTimerRunning?", quitTimerRunning)
        print("currentDate", currentDate)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        let currentDate = Date()
        
        //retrieve time of exit, calculate time in background, set
        let quitDate = UserDefaults.standard.object(forKey: "quitDate") as! Date
        print("quit date in will enter foreground:", quitDate)
        let passedSeconds = currentDate.timeIntervalSince(quitDate)
        UserDefaults.standard.set(passedSeconds, forKey: "secondsInBackground")
        print("passed seconds will enter foreground:", passedSeconds)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("app did become active..")
        let currentDate = Date()

        //retrieve time of exit, calculate time in background, set
        let quitTimerRunning = UserDefaults.standard.object(forKey: "quitTimerRunning") as? Bool

        if quitTimerRunning == true {
            let quitDate = UserDefaults.standard.object(forKey: "quitDate") as! Date
            print("quit date became activ:", quitDate)
            let passedSeconds = currentDate.timeIntervalSince(quitDate)
            UserDefaults.standard.set(passedSeconds, forKey: "secondsInBackground")
            print("passed seconds active:", passedSeconds)
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        print("app will terminate..")
        
        //set the time of exiting app to calculate time it was in background later
        let currentDate = Date()
        UserDefaults.standard.set(currentDate as Date, forKey:"quitDate")
        
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

