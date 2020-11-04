//
//  Mesg.swift
//  Example
//
//  Created by 龙格 on 2020/9/19.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import Foundation

public enum MesgType: Int {
    case single = 0
    case group
    case vmuc
}
/**
    接收到的信息数据模型
 */
public struct Mesg {
    public var fromUid: String
    public var toUid: String
    public var conversationId: String
    public var serverId: String
    public var text: String
    public var status: Int
    public var timestamp: TimeInterval
    public var localId: String?
    public var mesgType: MesgType
    
    public var isOutgoing: Bool {
        guard let passport = MavlMessage.shared.passport else {
            return false
        }
        return passport.uid == fromUid
    }

    init(topicModel: TopicModelProtocol) {
        fromUid = topicModel.from
        toUid = topicModel.to
        conversationId = topicModel.conversationId
        serverId = topicModel.serverId
        text = topicModel.text
        status = topicModel.status
        timestamp = topicModel.timestamp ?? Date().timeIntervalSince1970
        localId = topicModel.localId
        if topicModel.operation == 0 || topicModel.operation == 2 {
            mesgType = .group
        }else if topicModel.operation == 3 {
            mesgType = .vmuc
        }else {
            mesgType = .single
        }
    }
}
