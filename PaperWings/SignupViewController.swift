//
//  SignUpViewController.swift
//  PaperWings
//
//  Created by 윤병진 on 11/09/2019.
//  Copyright © 2019 darkKnight. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage

class SignupViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    let remoteConfig = RemoteConfig.remoteConfig()
    var color: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let statusBar = UIView()
        self.view.addSubview(statusBar)
        statusBar.snp.makeConstraints { (m) in
            m.right.top.left.equalTo(self.view)
            //m.height.equalTo(40)
        }
        
        color = remoteConfig["splash_background"].stringValue
        statusBar.backgroundColor = UIColor(hex: color!)
        
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(imagePicker)))
        
        signupButton.backgroundColor = UIColor(hex: color!)
        cancelButton.backgroundColor = UIColor(hex: color!)
        
        signupButton.addTarget(self, action: #selector(signupEvent), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelEvent), for: .touchUpInside)
    }
    
    @objc func imagePicker() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
        
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    internal func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey :Any]) {
        imageView.image = (info[UIImagePickerController.InfoKey.originalImage] as! UIImage)
        
        dismiss(animated: true, completion: nil)
    }
    
    @objc func signupEvent() {
        Auth.auth().createUser(withEmail: email.text!, password: password.text!) { (user, err) in
            let uid = user?.user.uid
            let image = self.imageView.image?.jpegData(compressionQuality: 0.1)
            
            let imageRef = Storage.storage().reference().child("userImages").child(uid!)
            
            imageRef.putData(image!, metadata: nil, completion: { (data, err) in
                imageRef.downloadURL(completion: { (url, err) in
                    let values = ["userName": self.name.text, "profileImageUrl": url?.absoluteString, "uid":Auth.auth().currentUser?.uid]
                    Database.database().reference().child("users").child(uid!).setValue(values, withCompletionBlock: {(err, ref) in
                        
                        if(err == nil) {
                            self.cancelEvent()
                        }
                    })
                })
            })
        }
    }
    
    @objc func cancelEvent() {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
          self.view.endEditing(true)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
