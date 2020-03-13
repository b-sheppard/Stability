//
//  LoginViewController.swift
//  balance
//
//  Created by Ben Sheppard on 7/10/19.
//  Copyright © 2019 Orb Mentality. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase
import FirebaseAuth

class LoginViewController: UIViewController {
    let white = UIColor(hex:15460841)
    let gray = UIColor(hex:5263695)
    let width = UIScreen.main.bounds.width
    let height = UIScreen.main.bounds.height
    let categoryNames = ["Sleep"]

    
    let username = UITextField()
    let password = UITextField()
    
    let signUp = UIButton()
    let login = UIButton()
    
    var ref:DatabaseReference?
    @objc func signUpUser() {
        signUp.shrinkGrowButton()
        Auth.auth().createUser(withEmail: username.text!, password: password.text!){ (user, error) in
            if error == nil {
                USER_PATH = Auth.auth().currentUser?.uid ?? "error"
                self.createDatabase()
                self.navigationController?.setNavigationBarHidden(true, animated: false)
                self.navigationController?.popViewController(animated: true)
            }
            else{
                let alertController = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                
                alertController.addAction(defaultAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    @objc func loginUser() {
        login.shrinkGrowButton()
        Auth.auth().signIn(withEmail: username.text!, password: password.text!) { (user, error) in
            if error == nil{
                USER_PATH = Auth.auth().currentUser?.uid ?? "error"
                self.navigationController?.setNavigationBarHidden(true, animated: false)
                self.navigationController?.popViewController(animated: true)
            }
            else {
                let alertController = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                
                alertController.addAction(defaultAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    @objc func shrinkGrowLogin() {
        login.shrinkGrowButton()
    }
    @objc func shrinkGrowSignUp() {
        signUp.shrinkGrowButton()
    }
    func setupTextField() {
        username.frame = CGRect(x: width/2, y: height/8, width: 3*width/4, height: 60)
        username.center.x = view.center.x
        username.textAlignment = .center
        username.textColor = gray
        username.backgroundColor = .white
        username.attributedPlaceholder = NSAttributedString(string: "Username",
                                                            attributes: [NSAttributedString.Key.foregroundColor: (UIColor.black.withAlphaComponent(0.4))])
        username.font = UIFont(name:"Futura", size:20)

        password.frame = CGRect(x: width/2, y: 2*height/8, width: 3*width/4, height: 60)
        password.center.x = view.center.x
        password.textAlignment = .center
        password.textColor = gray
        password.backgroundColor = .white
        password.isSecureTextEntry = true
        password.attributedPlaceholder = NSAttributedString(string: "Password",
        attributes: [NSAttributedString.Key.foregroundColor: (UIColor.black.withAlphaComponent(0.4))])
        password.font = UIFont(name:"Futura", size:20)
        
        view.addSubview(username)
        view.addSubview(password)
    }
    func setupSignUpButton() {
        signUp.frame = CGRect(x:width/2, y:3*height/8, width: 3*width/4, height:60)
        signUp.center.x = view.center.x
        signUp.backgroundColor = gray
        signUp.setTitle("Sign Up", for: .normal)
        signUp.setTitleColor(white, for: .normal)
        signUp.addTarget(self, action: #selector(LoginViewController.signUpUser), for: .touchUpInside)
        signUp.titleLabel?.font = UIFont(name:"Futura", size:20)
        signUp.addTarget(self, action: #selector(LoginViewController.shrinkGrowSignUp), for: .touchDown)
        view.addSubview(signUp)
    }
    func setupLoginButton() {
        login.frame = CGRect(x:width/2, y:height/2, width: 3*width/4, height: 60)
        login.center.x = view.center.x
        login.backgroundColor = gray
        login.setTitle("Login", for: .normal)
        login.addTarget(self, action: #selector(LoginViewController.loginUser), for: .touchUpInside)
        login.titleLabel?.font = UIFont(name:"Futura", size:20)
        login.addTarget(self, action: #selector(LoginViewController.shrinkGrowLogin), for: .touchDown)

        view.addSubview(login)
    }
    
    // Used for debugging (adds existing categories)
    func createDatabase() {
        //add category to database
        var i = 0
        let sleepTime = TotalTime()
        
        while i < categoryNames.count {
            ref?.child(USER_PATH + "/categories").child(categoryNames[i]).setValue(["Color" : colors[i],
                                                                                    "Name" : categoryNames[i],
                                                                                    "Tasks" : ""])
            // total time unscheduled
            sleepTime.color = colors[i] // gray
            sleepTime.name = categoryNames[i]
            sleepTime.duration = 0.0
            i += 1
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        if Auth.auth().currentUser?.uid != nil {
            print(Auth.auth().currentUser?.uid ?? "Cannot find uid")
            self.navigationController?.popViewController(animated: true)
        }
        
        ref = Database.database().reference()
        view.backgroundColor = white
        setupSignUpButton()
        setupLoginButton()
        setupTextField()
    }
}
