//
//  ChatSession.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/9/21.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import Foundation

struct ChatSession {
    var msg: Mesg
    
    var name: String {
        if msg.isGroup {
            guard let group = GroupsDao.fetchGroup(gid: msg.groupId) else {
                return "已删除群组-\(msg.groupId)"
            }
            return group.name
        }else {
            return msg.groupId.capitalized
        }
    }
    
    var toId: String {
        return msg.groupId
    }
    
    var isGroup: Bool {
        return msg.isGroup
    }
    
    var message: String {
        return (isGroup && UserCenter.isMe(uid: msg.fromUid)) ? "\(msg.fromUid.capitalized): \(msg.text)" : "\(msg.text)"
    }
    
    var datetime: String {
        return Date(timeIntervalSince1970: msg.timestamp).toString(with: .MMddHHmm)
    }
    
}
