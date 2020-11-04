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
//    appid/2/localid/togid      1vN
//    appid/2/localid/togid/serverid/fromuid
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

