//
//  ChatRoomsViewController.swift
//  PaperWings
//
//  Created by 윤병진 on 14/09/2019.
//  Copyright © 2019 darkKnight. All rights reserved.
//

import UIKit
import Firebase
import Kingfisher

class ChatRoomsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var uid: String?
    var chatRooms: [ChatModel]! = []
    var keys: [String] = []
    var destinationUsers: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.uid = Auth.auth().currentUser?.uid
        self.getChatroomsList()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.chatRooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RowCell", for: indexPath) as! CustomCell
        
        var destinationUid: String?
        
        for item in chatRooms[indexPath.row].users {
            if(item.key != self.uid) {
                destinationUid = item.key
                destinationUsers.append(destinationUid!)
            }
        }
        Database.database().reference().child("users").child(destinationUid!).observeSingleEvent(of: DataEventType.value, with: {(datasnapshot) in
            let userModel = UserModel()
            userModel.setValuesForKeys(datasnapshot.value as! [String: AnyObject])
            
            cell.labelTitle.text = userModel.userName
            let url = URL(string: userModel.profileImageUrl!)
            
            cell.imageview.layer.cornerRadius = cell.imageview.frame.width/2
            cell.imageview.layer.masksToBounds = true
            cell.imageview.kf.setImage(with: url)
            
            if(self.chatRooms[indexPath.row].comments.keys.count == 0) {
                return
            }
            
            let lastMessagekey = self.chatRooms[indexPath.row].comments.keys.sorted(){$0>$1}
            cell.labelLastMessage.text = self.chatRooms[indexPath.row].comments[lastMessagekey[0]]?.message
            
            let unixTime = self.chatRooms[indexPath.row].comments[lastMessagekey[0]]?.timestamp
            cell.labelTimestamp.text = unixTime?.toDayTime
            
        })
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if(self.destinationUsers[indexPath.row].count > 2) {
            let view = self.storyboard?.instantiateViewController(withIdentifier: "GroupChatViewController") as! GroupChatViewController
            view.destinationRoom = self.keys[indexPath.row]
    
            self.navigationController?.pushViewController(view, animated: true)
        }
        else {
            let destinationUid = self.destinationUsers[indexPath.row]
            let view = self.storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
            view.destinationUid = destinationUid
            
            self.navigationController?.pushViewController(view, animated: true)
        }
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.chatRooms.removeAll()
        viewDidLoad()
    }
    
    func getChatroomsList() {
        Database.database().reference().child("chatrooms").queryOrdered(byChild: "users/"+uid!).queryEqual(toValue: true).observeSingleEvent(of: DataEventType.value, with: {(datasnapshot) in
            for item in datasnapshot.children.allObjects as! [DataSnapshot] {
                
                if let chatRoomdic = item.value as? [String: AnyObject] {
                    let chatModel = ChatModel(JSON: chatRoomdic)
                    self.keys.append(item.key)
                    self.chatRooms.append(chatModel!)
                    
                    self.tableView.reloadData()
                }
            }
            
            
        })
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
class CustomCell: UITableViewCell{
    
    @IBOutlet weak var imageview: UIImageView!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelLastMessage: UILabel!
    @IBOutlet weak var labelTimestamp: UILabel!

}
