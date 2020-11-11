//
//  Mesg.swift
//  Example
//
//  Created by 龙格 on 2020/9/19.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import Foundation

public enum ConversationType: Int {
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
    public var conversationType: ConversationType
    public var isOutgoing: Bool

    public var text: String
    public var localId: String?
    public var serverId: String
    public var status: Int
    public var timestamp: TimeInterval
    
    init(topicModel: TopicModelProtocol) {
        let uid = (MavlMessage.shared.passport?.uid).value
        
        fromUid = topicModel.from
        toUid = topicModel.to
        isOutgoing = topicModel.from == uid

        if topicModel.operation == 2 {
            conversationType = .group
        }else if topicModel.operation == 3 {
            conversationType = .vmuc
        }else {
            conversationType = .single
        }
        serverId = topicModel.serverId
        text = topicModel.text
        status = topicModel.status
        timestamp = topicModel.timestamp
        localId = topicModel.localId
    }
}
