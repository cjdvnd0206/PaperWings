//
//  ViewController.swift
//  PaperWings
//
//  Created by 윤병진 on 11/09/2019.
//  Copyright © 2019 darkKnight. All rights reserved.
//

import UIKit
import SnapKit
import Firebase

class ViewController: UIViewController {
    
    var box = UIImageView()
    var remoteConfig: RemoteConfig!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        remoteConfig = RemoteConfig.remoteConfig()
        let remoteConfigSettings = RemoteConfigSettings()
        remoteConfig.configSettings = remoteConfigSettings
        remoteConfig.setDefaults(fromPlist: "RemoteConfigDefaults")
        
        remoteConfig.fetch(withExpirationDuration: TimeInterval(0)) {
            (status, error) -> Void in if status == .success {
                print("Config fetched!")
                self.remoteConfig.activate()
            } else {
                print("Config not Fetched")
                print("Error \(error!.localizedDescription)")
            }
            self.displayWelcome()
        }
        
        self.view.addSubview(box)
        box.snp.makeConstraints {
            (make) in make.center.equalTo(self.view)
        }
        box.image = #imageLiteral(resourceName: "loading_icon")

    }
    
    func displayWelcome() {
        let color = remoteConfig["splash_background"].stringValue
        let caps = remoteConfig["splash_message_caps"].boolValue
        let message = remoteConfig["splash_message"].stringValue
        
        if(caps) {
            let alert = UIAlertController(title: "공지사항", message: message, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "확인", style: UIAlertAction.Style.default, handler: {(action) in exit(0)}))
            
            self.present(alert, animated: true, completion: nil)
        }
        else {
            let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
            
            self.present(loginVC, animated: false, completion: nil)
        }
        self.view.backgroundColor = UIColor(hex: color!)
    }


}

extension UIColor {
    
    convenience init(hex: String){
        
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 1
        
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff
        
        self.init(
            red: CGFloat(r) / 0xff,
            green: CGFloat(g) / 0xff,
            blue: CGFloat(b) / 0xff, alpha: 1
        )
    }
}
