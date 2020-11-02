//
//  ChatViewController.swift
//  PaperWings
//
//  Created by 윤병진 on 12/09/2019.
//  Copyright © 2019 darkKnight. All rights reserved.
//

import UIKit
import Firebase
import Kingfisher

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var bottomContraint: NSLayoutConstraint!
    
    var uid: String?
    var chatRoomUid: String?
    
    var comments: [ChatModel.Comment] = []
    var userModel: UserModel?
    var databaseRef: DatabaseReference?
    var observe: UInt?
    var peopleCount: Int?
    
    public var destinationUid: String? // 채팅상대 uid
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        uid = Auth.auth().currentUser?.uid
        
        sendButton.addTarget(self, action: #selector(createRoom), for: .touchUpInside)
        checkChatRoom()
        self.tabBarController?.tabBar.isHidden = true
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if(self.comments[indexPath.row].uid == uid) {
            // 자신의 채팅을 보여줌
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
            // 상대방의 채팅을 보여줌
            let view = tableView.dequeueReusableCell(withIdentifier: "DestinationMessageCell", for: indexPath) as! DestinationMesseageCell
            view.labelName.text = userModel?.userName
            view.labelMessage.text = self.comments[indexPath.row].message
            view.labelMessage.numberOfLines = 0
            
            let url = URL(string: (self.userModel?.profileImageUrl)!)
            view.imageviewProfile.layer.cornerRadius = view.imageviewProfile.frame.width/2
            view.imageviewProfile.clipsToBounds = true
            view.imageviewProfile.kf.setImage(with: url)
            
            URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, err) in
                DispatchQueue.main.async {
                    view.imageviewProfile.image = UIImage(data: data!)
                    
                }
            }).resume()
            
            // 시간단위 표시
            if let time = self.comments[indexPath.row].timestamp {
                view.labelTimestamp.text = time.toDayTime
            }
            
            setReadCount(label: view.labelReadCounter, position: indexPath.row) // 읽음표시
            
            return view
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    // 시작
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification: )), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification: )), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    // 종료
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
        self.tabBarController?.tabBar.isHidden = false
        
        databaseRef?.removeObserver(withHandle: observe!)
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        if let keyboardSize = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            self.bottomContraint.constant = keyboardSize.height
        }
        
        UIView.animate(withDuration: 0, animations: { self.view.layoutIfNeeded()}, completion: {(complete) in
            if self.comments.count > 0 {
                self.tableView.scrollToRow(at: IndexPath(item: self.comments.count-1, section: 0), at: UITableView.ScrollPosition.bottom
                    , animated: true)
            }
        })
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        self.bottomContraint.constant = 20
        self.view.layoutIfNeeded()
    }
    
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    
    @objc func createRoom() {
        let createRoomInfo: Dictionary<String, Any> = ["users": [uid!: true, destinationUid!: true]]
        
        if(chatRoomUid == nil) {
            // 방 생성
            self.sendButton.isEnabled = false
            
            Database.database().reference().child("chatrooms").childByAutoId().setValue(createRoomInfo, withCompletionBlock: {(err, ref) in
                if(err == nil) {
                    self.checkChatRoom()
                }
            })
        }
        else {
            let value: Dictionary<String, Any> = ["uid": uid!, "message": messageTextField.text!, "timestamp": ServerValue.timestamp()]
            
            Database.database().reference().child("chatrooms").child(chatRoomUid!).child("comments").childByAutoId().setValue(value, withCompletionBlock: {(err, ref) in
                self.messageTextField.text = ""
            })
        }
    }
    
    func checkChatRoom() {
        Database.database().reference().child("chatrooms").queryOrdered(byChild: "users/"+uid!).queryEqual(toValue: true).observeSingleEvent(of: DataEventType.value, with: {(dataSnapshot) in
            for item in dataSnapshot.children.allObjects as! [DataSnapshot] {
                
                if let chatRoomdic = item.value as? [String: AnyObject] {
                    let chatModel = ChatModel(JSON: chatRoomdic)
                    if(chatModel?.users[self.destinationUid!] == true && chatModel?.users.count == 2) {
                        self.chatRoomUid = item.key
                        self.sendButton.isEnabled = true
                        self.getDestinationInfo()
                    }
                }
                
            }
        })
    }
    
    func getDestinationInfo() {
        Database.database().reference().child("users").child(self.destinationUid!).observeSingleEvent(of: DataEventType.value, with: {(datasnapshot) in
            self.userModel = UserModel()
            self.userModel?.setValuesForKeys(datasnapshot.value as! [String:Any])
            self.getMessageList()
        })
    }
    
    func setReadCount(label: UILabel?, position: Int?) {
        let readCount = self.comments[position!].readUsers.count
        
            Database.database().reference().child("chatrooms").child(chatRoomUid!).child("users").observeSingleEvent(of: DataEventType.value, with: {(datasnapshot) in
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
    
    func getMessageList() {
        databaseRef = Database.database().reference().child("chatrooms").child(self.chatRoomUid!).child("comments")
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
                            , animated: true)
                        
                    }
                })
            }
            else {
                self.tableView.reloadData()
                
                if self.comments.count > 0 {
                    self.tableView.scrollToRow(at: IndexPath(item: self.comments.count-1, section: 0), at: UITableView.ScrollPosition.bottom
                        , animated: true)
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

extension Int {
    
    var toDayTime: String {
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "yyyy.MM.dd HH:mm"
        
        let date = Date(timeIntervalSince1970: Double(self)/1000)
        
        return dateFormatter.string(from: date)
    }
}

class MyMesseageCell: UITableViewCell {
    
    @IBOutlet weak var labelMessage: UILabel!
    @IBOutlet weak var labelTimestamp: UILabel!
    @IBOutlet weak var labelReadCounter: UILabel!
    
}

class DestinationMesseageCell: UITableViewCell {
    
    @IBOutlet weak var labelMessage: UILabel!
    @IBOutlet weak var imageviewProfile: UIImageView!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelTimestamp: UILabel!
    @IBOutlet weak var labelReadCounter: UILabel!
    
}
