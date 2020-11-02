//
//  SelectFriendViewController.swift
//  PaperWings
//
//  Created by 윤병진 on 17/09/2019.
//  Copyright © 2019 darkKnight. All rights reserved.
//

import UIKit
import Firebase
import Kingfisher
import BEMCheckBox

class SelectFriendViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, BEMCheckBoxDelegate {
    
    var users = Dictionary<String, Bool>()
    var array: [UserModel] = []
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var makeChatRoomButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        Database.database().reference().child("users").observe(DataEventType.value, with: {(snapshot) in
            
            self.array.removeAll()
            
            let myUid = Auth.auth().currentUser?.uid
            
            for child in snapshot.children {
                let fchild = child as! DataSnapshot
                let userModel = UserModel()
                
                userModel.setValuesForKeys(fchild.value as! [String:Any])
                
                if(userModel.uid == myUid) {
                    continue
                }
                self.array.append(userModel)
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        })
        
        makeChatRoomButton.addTarget(self, action: #selector(createRoom), for: .touchUpInside)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return array.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let view = tableView.dequeueReusableCell(withIdentifier: "SelectFriendCell", for: indexPath) as! SelectFriendCell
        
        view.labelName.text = array[indexPath.row].userName
        view.imageviewProfile.kf.setImage(with: URL(string: array[indexPath.row].profileImageUrl!))
        view.checkBox.delegate = self
        view.checkBox.tag = indexPath.row
        
        return view
    }
 
    // 체크박스가 체크 됬을 때 발생하는 이벤트
    func didTap(_ checkBox: BEMCheckBox) {
        if(checkBox.on) {
            users[self.array[checkBox.tag].uid!] = true
        }
        else {
            users.removeValue(forKey: self.array[checkBox.tag].uid!)
        }
    }
    
    @objc func createRoom(){
        let myUid = Auth.auth().currentUser?.uid
        users[myUid!] = true
        let nsDic = users as NSDictionary
        
        Database.database().reference().child("chatrooms").childByAutoId().child("users").setValue(nsDic)
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

class SelectFriendCell: UITableViewCell {
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var checkBox: BEMCheckBox!
    @IBOutlet weak var imageviewProfile: UIImageView!
}
