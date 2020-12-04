//
//  Message.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/11/4.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import Foundation

enum ConversationType: Int {
    case single = 1
    case group
    case circle
}

struct Message {
    var id: Int32?
    var text: String
    var type: String    // text, image, video, audio, file, location, richtext, invalid
    var localAccount: String
    var remoteAccount: String
    var conversationId: String
    var localId: Int32
    var serverId: String
    var status: Int     // 0失败，1已发送，2已送达，3已读，
    var timestamp: TimeInterval
    var isOutgoing: Bool
    var conversationType: ConversationType
    
    private var imMesg: Mesg?
    
    init(_ imMesg: Mesg) {
        self.imMesg = imMesg
                
        let uid = (UserCenter.center.passport?.uid).value
        
        text = imMesg.text
        type = imMesg.type
        if imMesg.conversationType == .single {
            localAccount = imMesg.isOutgoing ? imMesg.fromUid : imMesg.toUid
            remoteAccount = imMesg.isOutgoing ? imMesg.toUid : imMesg.fromUid
        }else {
            // 群组
            if imMesg.isOutgoing {
                localAccount = imMesg.fromUid
                remoteAccount = imMesg.toUid
            }else {
                localAccount = uid
                remoteAccount = imMesg.fromUid
            }
        }
        if imMesg.conversationType == .group {
            conversationId = imMesg.toUid
        }else if imMesg.conversationType == .vmuc {
            conversationId = imMesg.toUid
        }else {
            if let passport = UserCenter.center.passport {
                conversationId = passport.uid == imMesg.fromUid ? imMesg.toUid : imMesg.fromUid
            }else {
                conversationId = imMesg.toUid
            }
        }
        localId = Int32(imMesg.localId.value) ?? 0
        serverId = imMesg.serverId
        status = imMesg.status
        timestamp = imMesg.timestamp
        if imMesg.conversationType == .vmuc {
            conversationType = .circle
        }else if imMesg.conversationType == .group {
            conversationType = .group
        }else {
            conversationType = .single
        }
        isOutgoing = imMesg.isOutgoing
    }
    
    init(id: Int32, text: String, local: String, remote: String, conversationId: String, localId: Int32, serverId: String, status: Int, timestamp: TimeInterval, conversationType: Int, isOutgoing: Bool, type: String = "text") {
        self.id = id
        self.text = text
        self.type = type
        self.localAccount = local
        self.remoteAccount = remote
        self.conversationId = conversationId
        self.localId = localId
        self.serverId = serverId
        self.status = status
        self.timestamp = timestamp
        self.isOutgoing = isOutgoing
        self.conversationType = ConversationType(rawValue: conversationType) ?? .single
    }
}
