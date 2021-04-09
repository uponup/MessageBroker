//
//  OperationUtils.swift
//  CocoaAsyncSocket
//
//  Created by 龙格 on 2020/11/4.
//

import Foundation

public enum FetchMessagesType: Int {
    case one = 1
    case more = 2
    
    var value: Int {
        switch self {
        case .one:
            return 1
        case .more:
            return 2
        }
    }
}

enum Operation {
    case createGroup
    case oneToOne(_ localId: String, _ toUid: String)
    case oneToMany(_ localId: String, _ toGid: String)
    case vitualGroup(_ localId: String, _ toGid: String)
    
    case joinGroup(_ toGid: String)
    case quitGroup(_ toGid: String)
    
    case uploadToken
    
    case fetchMsgs(_ from: String, _ type: FetchMessagesType, _ cursor: String, _ offset: Int)
    case msgReceipt(_ from: String, _ toId: String, _ serverId: String)
    
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
        case .msgReceipt:   return 500
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
        case .vitualGroup(_, let gid):
            return "\(topicPrefix)/\(gid)"
        case .joinGroup(let gid):
            return "\(topicPrefix)/\(gid)"
        case .quitGroup(let gid):
            return "\(topicPrefix)/\(gid)"
        case .uploadToken:
            return "\(topicPrefix)/_"
        case .fetchMsgs(let from, let type, let cursor, let offset):
            return "\(topicPrefix)/\(from)/\(type.value)/\(cursor)/\(offset)"
        case .msgReceipt(let from, let to, let serverId):
            return "\(topicPrefix)/\(to)/\(serverId)/\(from)"
        }
    }
    
    var localId: String {
        switch self {
        case .createGroup, .joinGroup, .quitGroup, .uploadToken, .fetchMsgs, .msgReceipt:
            return "0"
        case .oneToOne(let localId, _):
            return "\(localId)"
        case .oneToMany(let localId, _):
            return "\(localId)"
        case .vitualGroup(let localId, _):
            return "\(localId)"
        }
    }
    
    var isNeedCipher: Bool {
        switch self {
        case .oneToOne, .oneToMany, .vitualGroup, .fetchMsgs:
            return true
        default:
            return false
        }
    }
}
