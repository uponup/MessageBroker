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
    
    private var status: String? {
        didSet {
            if status == "online" {
                statusView.backgroundColor = UIColor.green
                labelStatus.text = "online"
            }else {
                statusView.backgroundColor = UIColor.darkGray
                labelStatus.text = "offline"
            }
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }

    func updateData(_ contact: ContactCellModel) {
        if let _ = contact.groupId {
            ivAvatar.image = #imageLiteral(resourceName: "chatroom_default")
        }else if let _ = contact.circleId {
            ivAvatar.image = #imageLiteral(resourceName: "chatroom_default")
            self.labelStatus.isHidden = true
            self.statusView.isHidden = true
        }else if let _ = contact.imAccount {
            ivAvatar.image = UIImage(named: contact.name.capitalized) ?? #imageLiteral(resourceName: "avatar_default")
        }
        
        labelName.text = contact.name.capitalized
        labelDetail.text = ""   //defail msg, just like signature, slogan, online status; default is “”
    }
}
