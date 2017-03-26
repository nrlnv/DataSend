//
//  GetViewController.swift
//  diplomaWithSidebar
//
//  Created by Елдос Нурланов on 23.03.17.
//  Copyright © 2017 kbtu. All rights reserved.
//

import UIKit
import Firebase

class GetViewController: UIViewController {
    
    //outlets
    
    @IBOutlet weak var keyTextField: UITextField!
    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var saveButton: UIButton!
    
    //getting image from Firebase storage 
    
    @IBAction func getButton(_ sender: UIButton) {
        self.dismissKeyboard()
        if urlTextField.text != "" {
            let name = urlTextField.text! + ".jpeg"
            let storageRef = FIRStorage.storage().reference().child(name)
            storageRef.data(withMaxSize: 5 * 1024 * 1024, completion:
                { (data, error) in
                    if let error = error {
                        print(error.localizedDescription)
                    }
                    else {
                        print(data)
                        self.imageView.image = UIImage(data: data!)
                        self.imageView.contentMode = .scaleAspectFit
                        self.saveButton.isEnabled = true
                    }
            })
        } else {
            let alert = UIAlertController(title: "Error", message: "Paste the link", preferredStyle: .alert)
            let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    //saving image to phone library
    
    @IBAction func saveImageToLibrary(_ sender: UIButton) {
        self.navigationController!.pushViewController(self.storyboard!.instantiateViewController(withIdentifier: "vcid"), animated: true)
        let imageRepresentation = UIImagePNGRepresentation(self.imageView.image!)
        let imageData = UIImage(data: imageRepresentation!)
        UIImageWriteToSavedPhotosAlbum(imageData!, nil, nil, nil)
        let alert = UIAlertController(title: "Completed", message: "Image has been saved!", preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        scrollViewUp()
        saveButton.isEnabled = false
    }

    //scrolling up views when keyboard appears
    
    func scrollViewUp() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if self.view.frame.origin.y == 0{
            self.view.frame.origin.y += 50
        }
        
        
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y -= 50
        }
        
    }
   

}
