//
//  PeopleViewController.swift
//  PaperWings
//
//  Created by 윤병진 on 12/09/2019.
//  Copyright © 2019 darkKnight. All rights reserved.
//

import UIKit
import SnapKit
import Firebase
import Kingfisher

class PeopleViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var array: [UserModel] = []
    var tableView: UITableView!
    let remoteConfig = RemoteConfig.remoteConfig()
    var color: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad!")
        // Do any additional setup after loading the view.
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PeopleViewTableCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (m) in
            m.top.equalTo(view)
            m.bottom.left.right.equalTo(view)
        }
        
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
        
        let selectFriendButton = Button()
        view.addSubview(selectFriendButton)
        selectFriendButton.snp.makeConstraints { (m) in
            m.bottom.equalTo(view).offset(-100)
            m.right.equalTo(view).offset(-20)
            m.width.height.equalTo(50)
        }
        
        selectFriendButton.backgroundColor = UIColor.cyan
        selectFriendButton.setImage(UIImage(named: "loading_icon"), for: UIControl.State.normal)
        selectFriendButton.addTarget(self, action: #selector(showSelectFriendController), for: .touchUpInside)
        selectFriendButton.layer.cornerRadius = 25
        selectFriendButton.layer.masksToBounds = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("viewWillAppear!")
    }
    
    @objc func showSelectFriendController() {
        self.performSegue(withIdentifier: "SelectFriendSegue", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return array.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! PeopleViewTableCell
        
        let imageView = cell.imageview!
        cell.addSubview(imageView)
        imageView.snp.makeConstraints { (m) in
            m.centerY.equalTo(cell)
            m.left.equalTo(cell).offset(10)
            m.height.width.equalTo(50)
        }
        let url = URL(string: array[indexPath.row].profileImageUrl!)
        
        imageView.layer.cornerRadius = 50/2
        imageView.clipsToBounds = true
        imageView.kf.setImage(with: url)
        
        let label = cell.label!
        label.snp.makeConstraints { (m) in
            m.centerY.equalTo(cell)
            m.left.equalTo(imageView.snp.right).offset(20)
        }
        label.text = array[indexPath.row].userName
        
        let labelComment = cell.labelComment!
        labelComment.snp.makeConstraints { (m) in
            m.centerX.equalTo(cell.uiviewCommentBackground)
            m.centerY.equalTo(cell.uiviewCommentBackground)
        }
        if let comment = array[indexPath.row].comment {
            labelComment.text = comment
        }
        cell.uiviewCommentBackground.snp.makeConstraints { (m) in
            m.right.equalTo(cell).offset(-20)
            m.centerY.equalTo(cell)
            
            if let count = labelComment.text?.count {
                m.width.equalTo(count*14)
            }
            else {
                m.width.equalTo(0)
            }
            m.height.equalTo(30)
        }
        color = remoteConfig["splash_background"].stringValue
        cell.uiviewCommentBackground.backgroundColor = UIColor(hex: color!)
        
        self.tableView.separatorStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let view = self.storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as? ChatViewController
        view?.destinationUid = self.array[indexPath.row].uid
        self.navigationController?.pushViewController(view!, animated: true)
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
class PeopleViewTableCell: UITableViewCell {
    var imageview: UIImageView! = UIImageView()
    var label: UILabel! = UILabel()
    var labelComment: UILabel! = UILabel()
    var uiviewCommentBackground: UIView! = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(imageview)
        self.addSubview(label)
        self.addSubview(uiviewCommentBackground)
        self.addSubview(labelComment)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
