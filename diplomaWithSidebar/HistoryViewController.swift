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
            self.navigationItem.title = ""
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
                    if message.from == self.currentUserEmail {
                        self.messages.append(message)
                    
                    }
                    self.tableView.reloadData()
                    
                    
                }
                
            }, withCancel: nil)
        
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
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Log Out", style: .plain, target: self, action: #selector(handleLogout))
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
        
        cell.textLabel?.text = "to: " + message.to!
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
