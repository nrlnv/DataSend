//
//  HistoryViewController.swift
//  diplomaWithSidebar
//
//  Created by Елдос Нурланов on 25.03.17.
//  Copyright © 2017 kbtu. All rights reserved.
//

import UIKit
import Firebase

class HistoryViewController: UITableViewController {
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    //var currentUserEmail: String = "1"
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        sideMenu()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Message", style: .plain, target: self, action: #selector(showInboxOutboxViewController))
        checkIfLoggedIn()
        
    }
    
    func fetchUserAndSetupNavBarTitle() {
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        
        FIRDatabase.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: {
            (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                self.navigationItem.title = dictionary["name"] as? String
                //self.currentUserEmail = dictionary["email"] as! String
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
                    
                    self.messages.append(message)
                    self.tableView.reloadData()
                    
                    
                }
                
            }, withCancel: nil)
        
        }, withCancel: nil)
    
    
    
    
    }
    func observeMessages() {
        let ref = FIRDatabase.database().reference().child("messages")
        ref.observe(.childAdded, with: { (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let message = Message()
                message.setValuesForKeys(dictionary)
//                if self.currentUserEmail == message.to {
//                    self.messages.append(message)
//                }
//                if let from = message.from {
//                    self.messagesDictionary[from] = message
//                    self.messages = Array(self.messagesDictionary.values)
//                }
                self.messages.append(message)
                self.tableView.reloadData()
                
            
            }
        
        }, withCancel: nil)
        
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
            fetchUserAndSetupNavBarTitle()
            //observeMessages()
            observeUserMessages()
        }
    }
    
    func showInboxOutboxViewController() {
        let inboxVC = InboxOutboxViewController(collectionViewLayout: UICollectionViewFlowLayout())
        navigationController?.pushViewController(inboxVC, animated: true)
    
    }
    
    //side menu handling
    
    func sideMenu() {
        if revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = "revealToggle:"
            self.view.addGestureRecognizer(revealViewController().panGestureRecognizer())
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cellId")
        let message = messages[indexPath.row]
        
        cell.textLabel?.text = message.to
        cell.detailTextLabel?.text = message.text
        return cell
    }


    

}
