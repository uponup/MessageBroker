//
//  ChatMessage.swift
//  Example
//
//  Created by CrazyWisdom on 16/1/1.
//  Copyright © 2016年 emqtt.io. All rights reserved.
//

import Foundation

enum SendingStatus {
    case sending
    case send           // 已发出
    case sendfail
    case sendSuccess    // 发送成功
}

class ChatMessage {
    
    private var mesg: Message
    var status: SendingStatus
    
    var isOutgoing: Bool {
        mesg.isOutgoing
    }
    
    var content: String {
        mesg.text
    }
    
    var uuid: String {
        mesg.serverId
    }
    
    var localId: String {
        mesg.localId
    }
    
    var timestamp: TimeInterval {
        mesg.timestamp
    }
    
    init(status: SendingStatus = .send, mesg: Message) {
        self.mesg = mesg
        self.status = status
    }
}

extension ChatMessage: Equatable {
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    static func < (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.timestamp < rhs.timestamp
    }
}
