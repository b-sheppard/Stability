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
    
    var ref:DatabaseReference?
    @objc func signUpUser() {
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
    func setupTextField() {
        username.frame = CGRect(x: width/2, y: height/8, width: width/2, height: 60)
        username.center.x = view.center.x
        username.placeholder = "Username"
        username.textColor = gray

        password.frame = CGRect(x: width/2, y: 2*height/8, width: width/2, height: 60)
        password.center.x = view.center.x
        password.placeholder = "Password"
        password.textColor = gray
        //password.isSecureTextEntry = true
        
        view.addSubview(username)
        view.addSubview(password)
    }
    func setupSignUpButton() {
        let signUp = UIButton(frame: CGRect(x:width/2, y:3*height/8, width: width/2, height:60))
        signUp.center.x = view.center.x
        signUp.backgroundColor = gray
        signUp.setTitle("Sign Up", for: .normal)
        signUp.setTitleColor(white, for: .normal)
        signUp.addTarget(self, action: #selector(LoginViewController.signUpUser), for: .touchUpInside)
        view.addSubview(signUp)
    }
    func setupLoginButton() {
        let login = UIButton(frame: CGRect(x:width/2, y:height/2, width: width/2, height: 60))
        login.center.x = view.center.x
        login.backgroundColor = gray
        login.setTitle("Login", for: .normal)
        login.addTarget(self, action: #selector(LoginViewController.loginUser), for: .touchUpInside)
        view.addSubview(login)
    }
    
    // Used for debugging (adds existing categories)
    func createDatabase() {
        //add category to database
        var i = 0
        while i < categoryNames.count {
            ref?.child(USER_PATH + "/categories").child(categoryNames[i]).setValue(["Color" : colors[i],
                                                                                    "Name" : categoryNames[i],
                                                                                    "Tasks" : ""])
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
