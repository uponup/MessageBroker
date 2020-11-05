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
        if msg.conversationType == .group {
            guard let group = GroupsDao.fetchGroup(gid: msg.conversationId) else {
                return "已删除群组-\(msg.conversationId)"
            }
            return group.name
            
        }else if msg.conversationType == .circle {
            guard let circle = CirclesDao.fetchCircle(circleId: msg.conversationId) else {
                return "已删除圈子-\(msg.conversationId)"
            }
            return circle.name
        }else {
            return msg.conversationId.capitalized
        }
    }
    
    var toId: String {
        return msg.conversationId
    }
    
    var isGroup: Bool {
        return msg.conversationType == .group
    }
    
    var isCircle: Bool {
        return msg.conversationType == .circle
    }
    
    var message: String {
        return msg.text
    }
    
    var datetime: String {
        return Date(timeIntervalSince1970: msg.timestamp).toString(with: .MMddHHmm)
    }
    
}
