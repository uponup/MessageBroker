//
//  Mesg.swift
//  Example
//
//  Created by 龙格 on 2020/9/19.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import Foundation

/**
    接收到的信息数据模型
 */
public struct Mesg {
    public var fromUid: String
    public var toUid: String
    public var groupId: String
    public var serverId: String
    public var text: String
    public var status: Int
    public var timestamp: TimeInterval
    public var localId: String?
    
    public var isGroup: Bool {
        fromUid != groupId
    }
    
//    56_peter,56_peter,05aff857d249c2DS,1600935023224, 2,   1600935023,9090##
//    Fromuid，Touid，   Gid，            Servermsgid，Status，Timestamp， Msg
    public init?(payload: String) {
        let segments = payload.components(separatedBy: ",")
        guard segments.count > 6 else { return nil }
        
        fromUid = segments[0]
        toUid = segments[1]
        groupId = segments[2]
        serverId = segments[3]
        status = Int(segments[4]) ?? 0
        timestamp = TimeInterval(segments[5])!
        let index = segments.count
        text = segments[6..<index].joined(separator: ",")
    }
    
    public init(fromUid: String, toUid: String, groupId: String, serverId: String, text: String, timestamp: TimeInterval, status: Int) {
        self.fromUid = fromUid
        self.toUid = toUid
        self.groupId = groupId
        self.serverId = serverId
        self.text = text
        self.timestamp = timestamp
        self.status = status
    }
}

// MARK: - Mesg数模转化
extension Mesg {
    
    public func toDict() -> [String: Any] {
        return [
            "fromUid": fromUid,
            "toUid": toUid,
            "groupId": groupId,
            "serverId": serverId,
            "text": text,
            "status": status,
            "timestamp": timestamp,
            "localId": localId ?? ""
        ]
    }
    
    public init(dict: [String: Any]) {
        self.fromUid = dict["fromUid"] as! String
        self.toUid = dict["toUid"] as! String
        self.groupId = dict["groupId"] as! String
        self.serverId = dict["serverId"] as! String
        self.text = dict["text"] as! String
        self.status = dict["status"] as! Int
        self.timestamp = dict["timestamp"]  as! TimeInterval
        self.localId = dict["localId"] as? String
    }
}
