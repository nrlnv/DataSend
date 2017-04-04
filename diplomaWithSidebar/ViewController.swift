//
//  ViewController.swift
//  diplomaWithSidebar
//
//  Created by Елдос Нурланов on 23.03.17.
//  Copyright © 2017 kbtu. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UIViewController {

    @IBOutlet weak var menuButton: UIBarButtonItem!
    var currentUserEmail: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sideMenu()
        self.navigationItem.title = "DataSend"
        checkIfLoggedIn()
    }
    
    //side menu handling
    
    func sideMenu() {
        if revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = "revealToggle:"
            self.view.addGestureRecognizer(revealViewController().panGestureRecognizer())
        }
    }
    //checking if user logged in
    
    func checkIfLoggedIn() {
        if FIRAuth.auth()?.currentUser?.uid == nil {
            do {
                try FIRAuth.auth()?.signOut()
                } catch let logoutError {
                print(logoutError)
                }
            
            return
        } else {
            fetchUserAndSetupNavBarTitle()
            
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Log Out", style: .plain, target: self, action: #selector(handleLogout))
        }
    }
    
    //setting name of current user to nav bar title
    
    func fetchUserAndSetupNavBarTitle() {
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        
        FIRDatabase.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: {
            (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                self.navigationItem.title = dictionary["name"] as? String
                self.currentUserEmail = dictionary["email"] as! String
            }
        }, withCancel: nil)
    }
    
    //logging out
    
    func handleLogout() {
        do {
            try FIRAuth.auth()?.signOut()
            self.navigationItem.title = "DataSend"
            self.navigationItem.rightBarButtonItem = nil
            let alert = UIAlertController(title: "Success!", message: "Successfully logged out", preferredStyle: .alert)
            let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
            
        } catch let logoutError {
            print(logoutError)
        }
        
    }
}

//hiding keyboard when tapping around

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
}
