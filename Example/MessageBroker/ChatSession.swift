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
                return msg.groupId
            }
            return group.name
        }else {
            let n = UserCenter.isMe(uid: msg.fromUid) ? msg.toUid : msg.fromUid
            return n.capitalized
        }
    }
    
    var gid: String {
        return msg.groupId  // group的话有gid，circle的话返回vmucid，contact的话返回fromUid
    }
    
    var isGroup: Bool {
        return msg.isGroup
    }
    
    var message: String {
        return (isGroup && UserCenter.isMe(uid: msg.fromUid)) ?  "\(msg.text)" : "\(msg.fromUid.capitalized): \(msg.text)"
    }
    
    var datetime: String {
        return Date(timeIntervalSince1970: msg.timestamp).toString(with: .MMddHHmm)
    }
    
}
