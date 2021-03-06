//
//  ChatSessionCell.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/9/21.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import UIKit

class ChatSessionCell: UITableViewCell {

    @IBOutlet weak var ivSessionIcon: UIImageView!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelDetail: UILabel!
    @IBOutlet weak var labelDate: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func updateData(session: ChatSession) {
        if session.isGroup {
            ivSessionIcon.image = #imageLiteral(resourceName: "cn_chatroom_default")
        }else if session.isCircle {
            ivSessionIcon.image = #imageLiteral(resourceName: "cn_circle_default")
        }else {
            ivSessionIcon.image = #imageLiteral(resourceName: "cn_single_default")
        }
        labelName.text = session.name
        
        labelDate.isHidden = false
        labelDetail.isHidden = false
        labelDetail.text = session.message
        labelDate.text = session.datetime
    }
}
