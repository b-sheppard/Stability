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

class TaskViewController: UIViewController, UITextFieldDelegate {
    
    let gray = UIColor(hex: colors[5])
    
    let MAX_CATEGORIES = 9;
    var categoryNames:[String] = ["+"]
    var categoryColors:[Int] = [colors[5]]
    var scrollView: UIScrollView!
    
    var ref:DatabaseReference?
    var handle:DatabaseHandle?
    
    // go to homeview
    @objc public func homeButtonTapped() {
        print("Home button pressed")
        let  vc =  self.navigationController?.viewControllers.filter({$0 is HomeViewController}).first
        
        self.navigationController?.popToViewController(vc!, animated: true)
    } // homeButtonTapped()

    //add new category
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
        print(type + " Category")
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
    
    func hideContentController(content: UIViewController) {
        content.willMove(toParent: nil)
        content.view.removeFromSuperview()
        content.removeFromParent()
    } // hideContentController()
    
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
        scrollView.backgroundColor = gray
        
        scrollView.showsHorizontalScrollIndicator = true;
        scrollView.showsVerticalScrollIndicator = true;
        
        scrollView.contentSize = CGSize(width: scrollWidth, height: scrollHeight * 2)
        
        //add dynamic buttons
        var col = 0
        var row:CGFloat = 1
        var buttonCount = 0
        for category in categoryNames {
            if col % 3 == 0 && col != 0 {
                row += 2
            }
            let button = UIButton(type: .custom)
            let x_pos = (5 + CGFloat(col % 3)*scrollWidth/3)
            let y_pos = (row)*scrollHeight/4
            button.frame = CGRect(x: x_pos, y: y_pos - 50, width: 110, height: 110)
            button.layer.cornerRadius = 0.5 * button.bounds.size.width
            button.clipsToBounds = true
            
            if category == "+" {
                button.setTitle(category, for: .normal)
                button.titleLabel?.font = UIFont(name:"Times New Roman", size: 80)
                button.setTitleColor(.white, for: .normal)
                button.backgroundColor = gray //gray
                button.addTarget(self, action: #selector(buttonTapped(sender:)), for: .touchUpInside)
            }
            else {
                button.setTitle(category, for: .normal)
                button.titleLabel?.font = UIFont(name:"Times New Roman", size: 30)
                button.setTitleColor(UIColor.black.withAlphaComponent(0.6), for: .normal)
                //button color
                let buttonColor = UIColor(hex: categoryColors[buttonCount])
                button.backgroundColor = buttonColor
                button.addTarget(self, action: #selector(buttonTapped(sender:)), for: .touchUpInside)
            }
 
            self.scrollView.addSubview(button)
            col += 1
            buttonCount += 1
        }
        view.addSubview(scrollView)
    } // createScrollView()
    
    //create newTask textfield and keyboard
    func createTextField() {
        let screensize: CGRect = UIScreen.main.bounds
        let screenWidth = screensize.width
        let screenHeight = screensize.height
        let taskTextField = UITextField(frame: CGRect(x: 20, y: screenHeight/8,
                                                      width: screenWidth - 40, height: 60))
        taskTextField.backgroundColor = .white
        taskTextField.borderStyle = .roundedRect
        taskTextField.placeholder = "this does nothing... for now"
        taskTextField.font = UIFont.systemFont(ofSize: 20.0);
        taskTextField.keyboardAppearance = .dark
        
        view.addSubview(taskTextField)
    } //createTextField()
    
    override func viewDidDisappear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    } // viewDidDisappear()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateLocalDatabase()
        
        ref = Database.database().reference()
        
        // updates category list if new category added
        handle = ref?.child("categories").observe(.childAdded, with: { (snapshot) in
            if let item = snapshot.childSnapshot(forPath: "/Name").value as? String {
                self.categoryNames.insert(item, at: 0)
                
            }
            if let color = snapshot.childSnapshot(forPath: "/Color").value as? Int {
                self.categoryColors.insert(color, at: 0)
            }
            self.createScrollView()
        })
        
        // updates category list if category removed
        handle = ref?.child("categories").observe(.childRemoved, with: { (snapshot) in
            if let item = snapshot.childSnapshot(forPath: "/Name").value as? String {
                if let position = self.categoryNames.firstIndex(of: item) {
                    self.categoryNames.remove(at: position)
                    print(item + " category removed")
                }
                self.createScrollView()
            }
        })

        view.backgroundColor = gray
        self.hideKeyboardWhenTappedAround()
        self.createTextField()
        
        self.title = "New Task"
        //creates right bar item
        let homeButton = UIBarButtonItem(title: "Home",
                                         style: .plain,
                                         target: self,
                                         action: #selector(TaskViewController.homeButtonTapped))
        homeButton.tintColor = .red
        self.navigationItem.rightBarButtonItem = homeButton
        self.navigationItem.setHidesBackButton(true, animated: false)
        
    } // viewDidLoad()
    
} // class TaskViewController()
