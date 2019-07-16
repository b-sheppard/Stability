//
//  ProfileViewController.swift
//  balance
//
//  Created by Ben Sheppard on 7/16/19.
//  Copyright © 2019 Orb Mentality. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth

class ProfileViewController: UIViewController {
    let white = UIColor(hex:15460841)
    let gray = UIColor(hex:5263695)
    
    @objc func signoutUser() {
        do {
            try Auth.auth().signOut()
        }
        catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        
        let login = LoginViewController()
        navigationController?.pushViewController(login, animated: false)
    }
    
    func addSignoutButton() {
        let x_pos = UIScreen.main.bounds.width/2
        let y_pos = UIScreen.main.bounds.height - 80
        
        let signout = UIButton()
        signout.frame = CGRect(x: x_pos - 150, y: y_pos, width: 300, height:60)
        signout.clipsToBounds = true
        signout.setTitle("Signout", for: .normal)
        signout.titleLabel?.font = UIFont(name:"Futura", size: 30)
        signout.setTitleColor(.red, for: .normal)
        signout.backgroundColor = gray
        signout.addTarget(self, action: #selector(signoutUser), for: .touchUpInside)
        signout.layer.cornerRadius = 10
        self.view.addSubview(signout)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barTintColor = white
        
        view.backgroundColor = white
        addSignoutButton()
    }
}
