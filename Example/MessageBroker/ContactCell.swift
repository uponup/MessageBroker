//
//  ContactCell.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/9/21.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import UIKit

class ContactCell: UITableViewCell {

    @IBOutlet weak var ivAvatar: UIImageView!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelDetail: UILabel!
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var labelStatus: UILabel!
    
    private var isOnline: Bool = false {
        didSet {
            if isOnline == true {
                statusView.backgroundColor = UIColor.green
                labelStatus.text = "online"
            }else {
                statusView.backgroundColor = UIColor.darkGray
                labelStatus.text = "offline"
            }
        }
    }
    
    private var model: ContactCellModel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        NotificationCenter.default.addObserver(self, selector: #selector(userStatusChangeAction), name: .userStatusDidChanged, object: nil)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }

    func updateData(_ contact: ContactCellModel) {
        model = contact
        if let _ = contact.groupId {
            ivAvatar.image = #imageLiteral(resourceName: "cn_chatroom_default")
            self.labelStatus.isHidden = true
            self.statusView.isHidden = true
        }else if let _ = contact.circleId {
            ivAvatar.image = #imageLiteral(resourceName: "cn_circle_default")
            self.labelStatus.isHidden = true
            self.statusView.isHidden = true
        }else if let _ = contact.imAccount {
            self.labelStatus.isHidden = false
            self.statusView.isHidden = false
            ivAvatar.image = #imageLiteral(resourceName: "cn_single_default")
        }
        
        labelName.text = isMe(contact.imAccount) ? "\(contact.name.capitalized)（yourself）" : contact.name.capitalized
        labelDetail.text = ""   //defail msg, just like signature, slogan, online status; default is “”
        
        refreshOnlineStatus()
    }
    
    @objc func userStatusChangeAction() {
        refreshOnlineStatus()
    }
    
    private func refreshOnlineStatus() {
        guard let model = model, let im = model.imAccount else { return }
        isOnline = StatusQueue.shared.isOnline(withImAccount: im)
    }
}
