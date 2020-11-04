//
//  ChatSession.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/9/21.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import Foundation

struct ChatSession {
    var msg: Message
    
    var name: String {
        if msg.isGroup {
            guard let group = GroupsDao.fetchGroup(gid: msg.conversationId) else {
                return "已删除群组-\(msg.conversationId)"
            }
            return group.name
        }else {
            return msg.conversationId.capitalized
        }
    }
    
    var toId: String {
        return msg.conversationId
    }
    
    var isGroup: Bool {
        return msg.isGroup
    }
    
    var message: String {
        return msg.text
    }
    
    var datetime: String {
        return Date(timeIntervalSince1970: msg.timestamp).toString(with: .MMddHHmm)
    }
    
}
