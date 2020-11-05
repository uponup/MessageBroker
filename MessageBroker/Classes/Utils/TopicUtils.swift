//
//  TopicUtils.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/9/22.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import Foundation

/**
 TopicModle的作用：隔离Mesg和topicStr
    在协议中，我们自定义了多种topic字符串，来实现不同的功能
    如果我们构造Mesg的时候，直接传入topic字符串，那么就会导致Mesg的构造方法过于复杂，所以我们设计了TopicModel，对Mesg进行解耦。
 */
protocol TopicModelProtocol {
    var appid: String { get set }
    var operation: Int { get set }      // 这儿operation选择Int型，上游Operation模型为enum，下游Mesg中为enum（单聊/群聊/虚拟群组）
    var from: String { get set }
    var to: String { get set }
    var text: String { get set }
    
    var localId: String { get set }
    var serverId: String { get set }
    var status: Int { set get }
    var timestamp: TimeInterval? { set get }
    var conversationId: String { get }
}

extension TopicModelProtocol {
    var conversationId: String {
        if operation == Operation.oneToOne("", "").value {
            guard let passport = MavlMessage.shared.passport else {
                return to
            }
            /**
             「A给B发」 和「B给A发」这两种case应该指定同一个gid，即对方账户
             */
            return passport.uid == from ? to : from
        }else {
            return to
        }
    }
    
    var isNeedDecrypt: Bool {
        if operation == 1
        || operation == 2
        || operation == 3 {
            return true
        }else {
            return false
        }
    }
}

// MARK: - Send
/**
    发送信息的Topic模型
    appid/operation/localId/toid
 */
struct SendTopicModel: TopicModelProtocol {
    var appid: String
    var operation: Int
    var from: String
    var to: String
    var text: String
    var localId: String
    var serverId: String
    var status: Int
    var timestamp: TimeInterval?
    
    init?(_ topic: String, _ mesgText: String) {
        guard let passport = MavlMessage.shared.passport else { return nil }
        let segments = topic.components(separatedBy: "/")
        guard segments.count >= 4, let op = Int(segments[1]) else { return nil }
        
        appid = segments[0]
        operation = op
        from = passport.uid
        to = segments[3]
        text = mesgText
        localId = segments[2]
        serverId = ""
        status = 0
    }
}

// MARK: - Receive
/**
    接收到信息的Topic模型
    appid/operation/localId/to/serverId/from
 */
struct ReceivedTopicModel: TopicModelProtocol {
    var appid: String
    var operation: Int
    var from: String
    var to: String
    var text: String
    var localId: String
    var serverId: String
    var status: Int = 2
    var timestamp: TimeInterval?
    
    init?(_ topic: String, _ mesgText: String) {
        let segments = topic.components(separatedBy: "/")
        guard segments.count >= 6, let op = Int(segments[1]) else { return nil }
        
        appid = segments[0]
        operation = op
        from = segments[5]
        to = segments[3]
        text = mesgText
        localId = segments[2]
        serverId = segments[4]
    }
}

// MARK: - History
/**
    历史信息Topic模型
    from/to/gid/serverId/status/timestamp/msg
 */
struct HistoryTopicModel: TopicModelProtocol {
    var appid: String
    var operation: Int
    var from: String
    var to: String
    var text: String
    var localId: String
    var serverId: String
    var status: Int
    var timestamp: TimeInterval?
    
    private var gid: String
    
    
    init?(_ topic: String) {
        let segments = topic.components(separatedBy: "/")
        guard segments.count >= 7 else { return nil }
        
        appid = MavlMessage.shared.appid
        operation = 401     //fake operation，历史信息不存在operation这个概念，客户端将其归纳到401中
        from = segments[0]
        to = segments[1]
        gid = segments[2]
        localId = ""
        serverId = segments[3]
        status = Int(segments[4]) ?? 2
        timestamp = TimeInterval(segments[5]) ?? 0
        text = segments[6]
    }
}


// MARK: - User Status
/**
    用户状态Topic模型
    appid/userstatus/uid/online
 */
struct UserStatusTopicModel {
    var appid: String
    var friendId: String
    
    init?(_ topic: String) {
        let segments = topic.components(separatedBy: "/")
        guard segments.count == 4 else { return nil }
        
        let status: String = segments[1]
        let type: String = segments[3]
        
        guard status == "userstatus" && type == "online" else { return nil }
        self.appid = segments[0]
        self.friendId = segments[2]
    }
}
