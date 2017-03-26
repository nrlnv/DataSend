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
            ring1.setProgress(value: 100, animationDuration: 4, completion: nil)
            let imageName = NSUUID().uuidString
            let storageRef = FIRStorage.storage().reference().child("\(imageName).jpeg")
            if let uploadData = UIImageJPEGRepresentation(self.imageView.image!, 0.8) {
                storageRef.put(uploadData, metadata: nil, completion:
                    { (metadata, error) in
                        if error != nil {
                            print(error)
                            return
                        }
                        self.ring1.isHidden = true
                        print(metadata)
                        UIPasteboard.general.string = imageName
                        if self.emailTextField.text != "" {
                            self.handleSend(imageName: imageName)
                        }
                        
                        print("image successfully loaded to Firebase storage")
                        darkView.isHidden = true
                        self.navigationController!.pushViewController(self.storyboard!.instantiateViewController(withIdentifier: "vcid"), animated: true)
                        let alert = UIAlertController(title: "Completed", message: "Image has been sent!", preferredStyle: .alert)
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
    func handleSend(imageName: String) {
        let ref = FIRDatabase.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        let fromId = FIRAuth.auth()!.currentUser!.uid
        
//        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
//            return
//        }
//        
//        FIRDatabase.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: {
//            (snapshot) in
//            if l et dictionary = snapshot.value as? [String: AnyObject] {
//                from = dictionary["email"] as! String
//            }
//        }, withCancel: nil)
//        getId()
        
        let values = ["text": imageName, "to": emailTextField.text!, "from": self.from]
        //childRef.updateChildValues(values)
        
        childRef.updateChildValues(values) { (error, ref) in
            
            if error != nil {
                print(error)
                return
            }
            let userMessagesRef = FIRDatabase.database().reference().child("user-messages").child(fromId)
            let messageId = childRef.key
            userMessagesRef.updateChildValues([messageId: 1])
            
        
        }
    }
    
//    var toId: String = ""
//    func getId() {
//        FIRDatabase.database().reference().child("users").observeSingleEvent(of: .value, with: {
//            (snapshot) in
//            
//            if let dictionary = snapshot.value as? [String: AnyObject] {
//                if self.emailTextField.text == dictionary["email"] as? String {
//                    self.toId = snapshot.key
//                }
//            }
//        
//        }, withCancel: nil)
//    
//    }
    
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
