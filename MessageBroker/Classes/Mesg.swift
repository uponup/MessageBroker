//
//  Mesg.swift
//  Example
//
//  Created by 龙格 on 2020/9/19.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import Foundation

@objc public enum ConversationType: Int {
    case single = 0
    case group
    case vmuc
}

/**
    接收到的信息数据模型
 */
@objcMembers public class Mesg: NSObject {
    public var fromUid: String
    public var toUid: String
    public var conversationType: ConversationType
    public var isOutgoing: Bool

    public var text: String
    public var type: String     // text, image, video, audio, file, location, richtext, invalid
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
        status = topicModel.status
        timestamp = topicModel.timestamp
        localId = topicModel.localId
        
        var content = topicModel.text
        if topicModel.isNeedDecrypt, let originText = EncryptUtils.decrypt(topicModel.text) {
            content = originText
        }
        
        let multiMedia = parseMediaMesg(content: content)
        type = multiMedia.type.rawValue
        if multiMedia.type == .location {
            guard let locationMedia = multiMedia as? LocationMedia else {
                text = multiMedia.content
                return
            }
            text = "latitude=\(locationMedia.latitude)&longitude=\(locationMedia.longitude)"
        }else {
            
            guard let normalMedia = multiMedia as? NormalMedia else {
                text = multiMedia.content
                return
            }
            text = normalMedia.mesg
        }
    }
}
