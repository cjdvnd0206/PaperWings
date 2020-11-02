//
//  AccountViewController.swift
//  PaperWings
//
//  Created by 윤병진 on 15/09/2019.
//  Copyright © 2019 darkKnight. All rights reserved.
//

import UIKit
import Firebase

class AccountViewController: UIViewController {

    @IBOutlet weak var conditionsCommentButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        conditionsCommentButton.addTarget(self, action: #selector(showAlert), for: .touchUpInside)
    }
    
    @objc func showAlert() {
        
        let alertController = UIAlertController(title: "상태 메시지", message: nil, preferredStyle: UIAlertController.Style.alert)
        
        alertController.addTextField{ (textfield) in
            textfield.placeholder = "상태메시지를 입력해주세요"
        }
        
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: {(action) in
            if let textField = alertController.textFields?.first {
                let dic = ["comment": textField.text!]
                let uid = Auth.auth().currentUser?.uid
                Database.database().reference().child("users").child(uid!).updateChildValues(dic)
            }
        }))
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel, handler: {(action) in
            
        }))
        self.present(alertController, animated: true, completion:  nil)
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
