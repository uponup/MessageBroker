//
//  ChatMessage.swift
//  Example
//
//  Created by CrazyWisdom on 16/1/1.
//  Copyright © 2016年 emqtt.io. All rights reserved.
//

import Foundation

enum SendingStatus: Int {
    case sending = -1   // 发送中
    case sendFail = 0   // 发送失败
    case send = 1       // 已发出
    case received = 2   // 已送达
    case read = 3       // 已读
}

class ChatMessage {
    
    private var mesg: Message
    var status: SendingStatus
    
    var type: String {
        mesg.type
    }
    
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
        "\(mesg.localId)"
    }
    
    var timestamp: TimeInterval {
        mesg.timestamp
    }
    
    var serverId: String {
        mesg.serverId
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
