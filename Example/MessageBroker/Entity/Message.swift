//
//  Message.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/11/4.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import Foundation

struct Message {
    var id: Int32?
    var text: String
    var localAccount: String
    var remoteAccount: String
    var conversationId: String
    var localId: String
    var serverId: String
    var status: Int
    var timestamp: TimeInterval
    var isGroup: Bool
    var isOutgoing: Bool
    
    
    private var imMesg: Mesg?
    
    init(_ imMesg: Mesg) {
        self.imMesg = imMesg
        
        text = imMesg.text
        localAccount = imMesg.isOutgoing ? imMesg.fromUid : imMesg.toUid
        remoteAccount = imMesg.isOutgoing ? imMesg.toUid : imMesg.fromUid
        conversationId = imMesg.conversationId
        localId = imMesg.localId.value
        serverId = imMesg.serverId
        status = imMesg.status
        timestamp = imMesg.timestamp
        isGroup = !(imMesg.mesgType == .single)
        isOutgoing = imMesg.isOutgoing
    }
    
    init(id: Int32, text: String, local: String, remote: String, conversationId: String, localId: String, serverId: String, status: Int, timestamp: TimeInterval, isGroup: Bool, isOutgoing: Bool) {
        self.id = id
        self.text = text
        self.localAccount = local
        self.remoteAccount = remote
        self.conversationId = conversationId
        self.localId = localId
        self.serverId = serverId
        self.status = status
        self.timestamp = timestamp
        self.isGroup = isGroup
        self.isOutgoing = isOutgoing
    }
}
