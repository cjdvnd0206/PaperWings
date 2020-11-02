//
//  GroupChatRoomViewController.swift
//  PaperWings
//
//  Created by 윤병진 on 17/09/2019.
//  Copyright © 2019 darkKnight. All rights reserved.
//

import UIKit
import Firebase

class GroupChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var textfieldMessage: UITextField!
    @IBOutlet weak var buttonSend: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    var destinationRoom: String?
    var uid: String?
    var comments: [ChatModel.Comment] = []
    var databaseRef: DatabaseReference?
    var observe: UInt?
    var users: [String: AnyObject]?
    var peopleCount: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        uid = Auth.auth().currentUser?.uid
        Database.database().reference().child("users").observeSingleEvent(of: DataEventType.value, with: { (datasnapshot) in
            self.users = (datasnapshot.value as! [String: AnyObject])
        })
        buttonSend.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        getMessageList()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if(self.comments[indexPath.row].uid == uid) {
            let view = tableView.dequeueReusableCell(withIdentifier: "MyMessageCell", for: indexPath) as! MyMesseageCell
            view.labelMessage.text = self.comments[indexPath.row].message
            view.labelMessage.numberOfLines = 0
            
            view.labelTimestamp.text = self.comments[indexPath.row].message
            view.labelTimestamp.numberOfLines = 0
            
            if let time = self.comments[indexPath.row].timestamp {
                view.labelTimestamp.text = time.toDayTime
            }
            
            setReadCount(label: view.labelReadCounter, position: indexPath.row)
            
            return view
        }
        else {
            let destinationUser = users![self.comments[indexPath.row].uid!]
            let view = tableView.dequeueReusableCell(withIdentifier: "DestinationMessageCell", for: indexPath) as! DestinationMesseageCell
            view.labelName.text = destinationUser!["userName"] as! String
            view.labelMessage.text = self.comments[indexPath.row].message
            view.labelMessage.numberOfLines = 0
            
            let imageUrl = destinationUser!["profileImageUrl"] as! String
            let url = URL(string: imageUrl)
            view.imageviewProfile.layer.cornerRadius = view.imageviewProfile.frame.width/2
            view.imageviewProfile.clipsToBounds = true
            view.imageviewProfile.kf.setImage(with: url)
            
            URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, err) in
                DispatchQueue.main.async {
                    view.imageviewProfile.image = UIImage(data: data!)
                    
                }
            }).resume()
            
            if let time = self.comments[indexPath.row].timestamp {
                view.labelTimestamp.text = time.toDayTime
            }
            
            setReadCount(label: view.labelReadCounter, position: indexPath.row)
            
            return view
        }
    }
    
    @objc func sendMessage() {
        let value: Dictionary <String, Any> = ["uid": uid!, "message": textfieldMessage.text!, "timestamp": ServerValue.timestamp()]
        
        Database.database().reference().child("chatrooms").child(destinationRoom!).child("comments").childByAutoId().setValue(value) {(err, ref) in
            self.textfieldMessage.text = ""
        }
    }

    func getMessageList() {
        databaseRef = Database.database().reference().child("chatrooms").child(self.destinationRoom!).child("comments")
        observe = databaseRef?.observe(DataEventType.value, with: { (datasnapshot) in
            self.comments.removeAll()
            var readUserDic: Dictionary<String, AnyObject> = [:]
            
            for item in datasnapshot.children.allObjects as! [DataSnapshot] {
                let key = item.key as String
                let comment = ChatModel.Comment(JSON: item.value as! [String: AnyObject])
                let commentModify = ChatModel.Comment(JSON: item.value as! [String: AnyObject])
                
                commentModify?.readUsers[self.uid!] = true
                readUserDic[key] = commentModify?.toJSON() as! NSDictionary
                self.comments.append(comment!)
            }
            
            let nsDic = readUserDic as NSDictionary
            
            if(self.comments.last?.readUsers.keys == nil) {
                return
            }
            
            if(!(self.comments.last?.readUsers.keys.contains(self.uid!))!) {
                datasnapshot.ref.updateChildValues(nsDic as! [AnyHashable: Any], withCompletionBlock: { (err, ref) in
                    self.tableView.reloadData()
                    
                    if self.comments.count > 0 {
                        self.tableView.scrollToRow(at: IndexPath(item: self.comments.count-1, section: 0), at: UITableView.ScrollPosition.bottom
                            , animated: false)
                        
                    }
                })
            }
            else {
                self.tableView.reloadData()
                
                if self.comments.count > 0 {
                    self.tableView.scrollToRow(at: IndexPath(item: self.comments.count-1, section: 0), at: UITableView.ScrollPosition.bottom
                        , animated: false)
                }
            }
        })
    }
    
    func setReadCount(label: UILabel?, position: Int?) {
        let readCount = self.comments[position!].readUsers.count
        
        Database.database().reference().child("chatrooms").child(destinationRoom!).child("users").observeSingleEvent(of: DataEventType.value, with: {(datasnapshot) in
            let dic = datasnapshot.value as! [String: Any]
            
            if(self.peopleCount == nil) {
                self.peopleCount = dic.count
                let noReadCount = self.peopleCount! - readCount
                
                if(noReadCount > 0) {
                    label?.isHidden = false
                    label?.text = String(noReadCount)
                }
                else {
                    label?.isHidden = true
                }
            }
            else {
                
                self.peopleCount = dic.count
                let noReadCount = self.peopleCount! - readCount
                
                if(noReadCount > 0) {
                    label?.isHidden = false
                    label?.text = String(noReadCount)
                }
                else {
                    label?.isHidden = true
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
