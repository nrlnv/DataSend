//
//  SendViewController.swift
//  diplomaWithSidebar
//
//  Created by Елдос Нурланов on 23.03.17.
//  Copyright © 2017 kbtu. All rights reserved.
//

import UIKit
import Firebase
import UICircularProgressRing
import CryptoSwift

class SendViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UICircularProgressRingDelegate {
    
    //outlets
    @IBOutlet weak var keyTextField: UITextField!
    @IBOutlet weak var sendImageToStorageButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var sendLabel: UILabel!
    @IBOutlet weak var sendButtonTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var ring1: UICircularProgressRingView!
    var from: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        keyTextField.text = String.random()
        ring1.isHidden = true
        ring1.animationStyle = kCAMediaTimingFunctionLinear
        ring1.backgroundColor = UIColor.init(red: 29/255, green: 10/255, blue: 31/255, alpha: 0.01)
        ring1.delegate = self
        checkIfLoggedIn()
        self.hideKeyboardWhenTappedAround()
        scrollViewUp()
        fetchUserAndSetupNavBarTitle()
    }
    
    func fetchUserAndSetupNavBarTitle() {
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        
        FIRDatabase.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: {
            (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                self.navigationItem.title = dictionary["name"] as? String
                self.from = dictionary["email"] as! String
            }
        }, withCancel: nil)
    }
    
    func finishedUpdatingProgress(forRing ring: UICircularProgressRingView) {
        if ring === ring1 {
            print("From delegate: Ring 1 finished")
        } 
    }
    
    //adding image
    
    @IBAction func addImageButton(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("canceled picker!")
        dismiss(animated: true, completion: nil)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        self.sendLabel.isHidden = true
        self.plusButton.backgroundColor = UIColor.init(red: 29/255, green: 10/255, blue: 31/255, alpha: 0.1)
        var selectedImageFromPicker: UIImage?
        if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage{
            selectedImageFromPicker = originalImage
        }
        if let selectedImage = selectedImageFromPicker {
            self.imageView.contentMode = .scaleAspectFit
            self.imageView.image = selectedImage
        }
        dismiss(animated: true, completion: nil)
    }
    
    //sending image to Firebase storage
    
    @IBAction func sendImageToStorage(_ sender: UIButton) {
        self.dismissKeyboard()
        if self.imageView.image != nil {
            let darkView = UIView.init(frame: self.view.frame)
            darkView.backgroundColor = UIColor.init(red: 29/255, green: 10/255, blue: 31/255, alpha: 0.8)
            self.view.addSubview(darkView)
            self.view.bringSubview(toFront: ring1)
            ring1.isHidden = false
            ring1.animationStyle = kCAMediaTimingFunctionLinear
            ring1.setProgress(value: 99, animationDuration: 4, completion: nil)
            let imageName = NSUUID().uuidString
            let storageRef = FIRStorage.storage().reference().child("\(imageName).jpeg")
            //print("image name: " + imageName)
            
            let input = imageName
            let key = self.keyTextField.text
            let iv = "gqLOHUioQ0QjhuvI"
            let en = try! input.aesEncrypt(key: key!, iv: iv)
            
            print("link: " + en)
            
            
            
            
            
            
            
            
            
            if let uploadData = UIImageJPEGRepresentation(self.imageView.image!, 0.8) {
                storageRef.put(uploadData, metadata: nil, completion:
                    { (metadata, error) in
                        if error != nil {
                            print(error)
                            return
                        }
                        self.ring1.isHidden = true
                        //print(metadata)
                        //UIPasteboard.general.string = imageName
                        //UIPasteboard.general.string = self.keyTextField.text
                        if self.emailTextField.text != "" {
                            self.handleSend(imageName: en)
                            UIPasteboard.general.string = self.keyTextField.text
                        } else {
                        
                        UIPasteboard.general.string = en + ", " + self.keyTextField.text!
                        
                        }
                        
                        print("image successfully loaded to Firebase storage")
                        darkView.isHidden = true
                        self.navigationController!.pushViewController(self.storyboard!.instantiateViewController(withIdentifier: "vcid"), animated: true)
                        let alert = UIAlertController(title: "Completed", message: "The key copied to clipboard!", preferredStyle: .alert)
                        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
                        alert.addAction(action)
                        self.present(alert, animated: true, completion: nil)
                    
                })
            }
        } else {
            let alert = UIAlertController(title: "Error", message: "No image to sent!", preferredStyle: .alert)
            let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    //sending name of image name to recipient
    var toId: String = ""
    func handleSend(imageName: String) {
        let ref = FIRDatabase.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        let fromId = FIRAuth.auth()!.currentUser!.uid
        let timestamp = NSNumber(value: Int(NSDate().timeIntervalSince1970))
        
        FIRDatabase.database().reference().child("users").observe(.value, with: {(snapshot) in
            let dictionary = snapshot.value as? [String: AnyObject]
            //print(dictionary!)
            //print("id is: " + toId!)
            for (theKey, theValue) in dictionary! {
                for (key, value) in theValue as! NSDictionary {
                    if key as! String == "email" {
                        if self.emailTextField.text == value as! String {
                            self.toId = theKey
                            //print("vnutri "+self.toId)
                            
//                            let input = imageName
//                            let key = self.keyTextField.text
//                            let iv = "gqLOHUioQ0QjhuvI"
//                            let en = try! input.aesEncrypt(key: key!, iv: iv)
//                            
//                            print("link: " + en)
                            
                            
                            print("hi there: " + imageName)
                            
                            
                            let values = ["text": imageName, "to": self.emailTextField.text!, "from": self.from, "timestamp": timestamp] as [String : Any]
                            //print("err:"+self.toId)
                            childRef.updateChildValues(values) { (error, ref) in
                                
                                if error != nil {
                                    print(error)
                                    return
                                }
                                let userMessagesRef = FIRDatabase.database().reference().child("user-messages").child(fromId)
                                let messageId = childRef.key
                                userMessagesRef.updateChildValues([messageId: 1])
                                
                                let recipientUserMessagesRef = FIRDatabase.database().reference().child("user-messages").child(self.toId)
                                recipientUserMessagesRef.updateChildValues([messageId: 1])
                                
                            }
                        }
                    } 
                }
            }
            
            
        }
            , withCancel: nil)
        
    }
    
    
    //scrolling up views when keyboard appears
    
    func scrollViewUp() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if self.view.frame.origin.y == 0 {
            self.view.frame.origin.y -= 100
        }
        
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y += 100
        }
    }
    
    //checking if logged in, if not then email text field is hidden, else is not hidden
    
    func checkIfLoggedIn() {
        if FIRAuth.auth()?.currentUser?.uid == nil {
            emailTextField.isHidden = true
            sendButtonTopConstraint.constant = -40
            return
        } else {
            emailTextField.isHidden = false
            sendButtonTopConstraint.constant = 10
        }
    }
    
    

}

extension String {
    
    static func random(length: Int = 16) -> String {
        let base = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var randomString: String = ""
        
        for _ in 0..<length {
            let randomValue = arc4random_uniform(UInt32(base.characters.count))
            randomString += "\(base[base.index(base.startIndex, offsetBy: Int(randomValue))])"
        }
        return randomString
    }

    func aesEncrypt(key: String, iv: String) throws -> String {
        let data = self.data(using: .utf8)!
        let encrypted = try! AES(key: key, iv: iv, blockMode: .CBC, padding: PKCS7()).encrypt([UInt8](data))
        let encryptedData = Data(encrypted)
        return encryptedData.base64EncodedString()
    }



}
