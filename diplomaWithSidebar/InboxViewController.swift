//
//  InboxViewController.swift
//  diplomaWithSidebar
//
//  Created by Елдос Нурланов on 26.03.17.
//  Copyright © 2017 kbtu. All rights reserved.
//

import UIKit
import Firebase

class InboxViewController: UITableViewController {

    @IBOutlet weak var menuButton: UIBarButtonItem!
    var currentUserEmail: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sideMenu()
        self.navigationItem.title = "DataSend"
        checkIfLoggedIn()
    }
    
    func handleLogout() {
        do {
            try FIRAuth.auth()?.signOut()
            self.navigationItem.title = "DataSend"
            self.navigationItem.rightBarButtonItem = nil
            self.navigationController!.pushViewController(self.storyboard!.instantiateViewController(withIdentifier: "vcid"), animated: true)
            let alert = UIAlertController(title: "Success!", message: "Successfully logged out", preferredStyle: .alert)
            let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
            
        } catch let logoutError {
            print(logoutError)
        }
        
    }
    
    func checkIfLoggedIn() {
        if FIRAuth.auth()?.currentUser?.uid == nil {
            do {
                try FIRAuth.auth()?.signOut()
            } catch let logoutError {
                print(logoutError)
            }
            
            return
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Log Out", style: .plain, target: self, action: #selector(handleLogout))
            fetchUserAndSetupNavBarTitle()
            observeUserMessages()
            
        }
    }
    
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
    
    var messages = [Message]()
    //var messagesDictionary = [String: Message]()
    
    func observeUserMessages() {
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        let ref = FIRDatabase.database().reference().child("user-messages").child(uid)
        ref.observe(.childAdded, with: {
            (snapshot) in
            
            let messageId = snapshot.key
            let messagesReference = FIRDatabase.database().reference().child("messages").child(messageId)
            messagesReference.observeSingleEvent(of: .value, with: {
                (snapshot) in
                if let dictionary = snapshot.value as? [String: AnyObject] {
                    let message = Message()
                    
                    message.setValuesForKeys(dictionary)
                    if message.to == self.currentUserEmail {
                        self.messages.append(message)
                        
                    }
                    self.messages.sort(by: {(message1, message2) -> Bool in
                        return (message1.timestamp?.intValue)! > (message2.timestamp?.intValue)!
                    })
                    self.tableView.reloadData()
                    
                    
                }
                
            }, withCancel: nil)
            
        }, withCancel: nil)
        
    }
    
    func sideMenu() {
        if revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = "revealToggle:"
            self.view.addGestureRecognizer(revealViewController().panGestureRecognizer())
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let message = messages[indexPath.row]
        cell.textLabel?.text = "from: " + message.from!
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 14.0)
        cell.detailTextLabel?.text = message.text
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = tableView.cellForRow(at: indexPath)
        UIPasteboard.general.string = selectedItem?.detailTextLabel?.text
        let alert = UIAlertController(title: "Success!", message: "Link copied to clipboard!", preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
    

}
