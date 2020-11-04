//
//  SettingController.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/9/21.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import UIKit

class SettingController: UIViewController {

    @IBOutlet weak var ivAvatar: UIImageView!
    @IBOutlet weak var labelAccount: UILabel!
    @IBOutlet weak var btnLogout: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        btnLogout.setBackgroundImage(#imageLiteral(resourceName: "btn_disable"), for: .disabled)
        btnLogout.isEnabled = MavlMessage.shared.isLogin
        if MavlMessage.shared.isLogin {
            ivAvatar.image = #imageLiteral(resourceName: "iv_chat_local")
            labelAccount.text = MavlMessage.shared.passport?.uid.capitalized
            navigationItem.title = MavlMessage.shared.passport?.uid.capitalized
        }else {
            ivAvatar.image = #imageLiteral(resourceName: "avatar_default")
            navigationItem.title = "Not Login"
        }
    }
    
    @IBAction func logoutAction(_ sender: Any) {
        guard let passport = MavlMessage.shared.passport else {  return }
        
        navigationItem.title = "Not Login"
        ivAvatar.image = #imageLiteral(resourceName: "avatar_default")
        labelAccount.text = "\(passport.uid.capitalized)（Last login）"
        btnLogout.isEnabled = false
        
        MavlMessage.shared.logout()
    }
}
