//
//  TopicUtils.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/9/22.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import Foundation
   
//收到 appid/0/localid/togid/serverid/fromid
//    appid/1/localid/touid/serverid/fromuid
//    appid/2/localid/togid/serverid/fromuid

//    peter发给bob：56/1/1/bob/1604406789700/peter
//    bob发给peter：56/1/2/peter/1604406911908/bob

protocol TopicPayload {
    func payload(status: Int, timestamp: TimeInterval, text: String) -> String
}
/**
    接收的Topic模型
    56/2/1/05b048e53e813dMJ/1603684050822/peter       群组发给peter
    56/2/1/05b3304c425c72DS/1604395116895/ss            群组发给ss
 */
struct TopicModel {
    var appid: String
    var operation: Int
    var localId: String
    var to: String
    var from: String
    var serverId: String
    var isGroupMsg: Bool {
        operation == 2 || operation == 0
    }
    var gid: String {
//        56/1/5/peter/1604407229084/bob
        if isGroupMsg {
            return to
        }else {
            guard let passport = MavlMessage.shared.passport else {
                return to
            }
            /**
             「A给B发」 和「B给A发」这两种case应该指定同一个gid，即对方账户
             */
            return passport.uid == from ? to : from
        }
    }
    
    init?(_ topic: String) {
        let segments = topic.components(separatedBy: "/")
        guard segments.count >= 6, let op = Int(segments[1]) else { return nil }
        
        appid = segments[0]
        operation = op
        localId = appid == MavlMessage.shared.appid ? segments[2] : ""
        to = segments[3]
        serverId = segments[4]
        from = segments[5]
    }
}

extension TopicModel: TopicPayload {
    //Fromuid，Touid，   Gid，            Servermsgid，Status，Timestamp， Msg
    func payload(status: Int, timestamp: TimeInterval, text: String) -> String {
        "\(from),\(to),\(gid),\(serverId),\(status),\(timestamp),\(text)"
    }
}


//发送 appid/0/localid/gid            create group
//    appid/1/localid/toid           1v1
//    appid/2/clientmsgid/togid      1vN

/**
    发送的Topic模型
    56/2/2/05b048e53e813dMJ
 */

struct SendingTopicModel {
    var appid: String
    var operation: Int
    var localId: String
    var to: String
    var isGroupMsg: Bool {
        operation == 2 || operation == 1
    }
    var gid: String {
        return to   //不论是一对一，还是一对多，在自定义协议中只有toId的概念。
    }
    
    
    init?(_ topic: String) {
        let segments = topic.components(separatedBy: "/")
        guard segments.count >= 4, let op = Int(segments[1]) else { return nil }
        
        appid = segments[0]
        operation = op
        localId = segments[2]
        to = segments[3]
    }
}

extension SendingTopicModel: TopicPayload {
    //Fromuid，Touid，   Gid，            Servermsgid，Status，Timestamp， Msg
    func payload(status: Int, timestamp: TimeInterval = Date().timeIntervalSince1970, text: String) -> String {
        guard let passport = MavlMessage.shared.passport else {
            return ""
        }
        return "\(passport.uid),\(to),\(gid),,\(status),\(timestamp),\(text)"
    }
}



//用户状态  appid/userstatus/uid/online

/**
    用户状态Topic模型
 */
struct StatusTopicModel {
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

// MARK: - Operation
public enum FetchMessagesType: Int {
    case one = 1
    case more
}

enum Operation {
    case createGroup
    case oneToOne(_ localId: UInt16, _ toUid: String)
    case oneToMany(_ localId: UInt16, _ toGid: String)
    case vitualGroup(_ toGid: String)
    
    case joinGroup(_ toGid: String)
    case quitGroup(_ toGid: String)
    
    case uploadToken
    
    case fetchMsgs(_ from: String, _ type: FetchMessagesType, _ cursor: String, _ offset: Int)
    
    var value: Int {
        switch self {
        case .createGroup:  return 0
        case .oneToOne:     return 1
        case .oneToMany:    return 2
        case .vitualGroup:  return 3
            
        case .joinGroup:    return 201
        case .quitGroup:    return 202
            
        case .uploadToken:  return 300
            
        case .fetchMsgs:    return 401
        }
    }
    
    
    var topic: String {
        let topicPrefix = "\(MavlMessage.shared.appid)/\(value)/\(localId)"
        
        switch self {
        case .createGroup:
            return "\(topicPrefix)/_"
        case .oneToOne(_, let uid):
            return "\(topicPrefix)/\(uid)"
        case .oneToMany(_, let gid):
            return "\(topicPrefix)/\(gid)"
        case .vitualGroup(let gid):
            return "\(topicPrefix)/\(gid)"
        case .joinGroup(let gid):
            return "\(topicPrefix)/\(gid)"
        case .quitGroup(let gid):
            return "\(topicPrefix)/\(gid)"
        case .uploadToken:
            return "\(topicPrefix)/_"
        case .fetchMsgs(let from, let type, let cursor, let offset):
            return "\(topicPrefix)/\(from)/\(type.rawValue)/\(cursor)/\(offset)"
        }
    }
    
    var localId: String {
        switch self {
        case .createGroup, .vitualGroup, .joinGroup, .quitGroup, .uploadToken, .fetchMsgs:
            return "0"
        case .oneToOne(let localId, _):
            return "\(localId)"
        case .oneToMany(let localId, _):
            return "\(localId)"
        }
    }
}

// MARK: OptionalExtension--String
extension Optional where Wrapped == String {
    public var value: String {
        switch self {
        case .none:
            return ""
        case .some(let v):
            return v;
        }
    }
}
