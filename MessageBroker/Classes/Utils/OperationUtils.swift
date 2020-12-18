//
//  OperationUtils.swift
//  CocoaAsyncSocket
//
//  Created by 龙格 on 2020/11/4.
//

import Foundation

/**
 Opeartion的作用：对协议规则进行抽象，屏蔽了具体操作的参数和MQTT交互细节
    - 在构造Operation的时候，专注于构造参数
    - 在使用MQTT的时候，直接获取topic和payload即可
 */
enum Operation {
    case createGroup(_ users: Set<String>)
    case oneToOne(_ localId: String, _ toUid: String, _ msg: String)
    case oneToMany(_ localId: String, _ toGid: String, _ msg: String)
    case vitualGroup(_ localId: String, _ toGid: String, _ users: Set<String>, _ msg: String)
    
    case joinGroup(_ toGid: String)
    case quitGroup(_ toGid: String)
    
    case uploadToken(_ deviceToken: String, _ env: String, _ platform: String, _ deliverOnPush: Bool)
    
    case fetchMsgs(_ from: String, _ type: FetchMessagesType, _ cursor: String, _ offset: Int)
    case msgReceipt(_ from: String, _ toId: String, _ serverId: String, _ state: ReceiptState)
    case msgTransparent(_ toId: String, _ action: String, _ ext: [String: Any])
    
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
        case .msgTransparent: return 501
        }
    }
    
    var topic: String {
        let topicPrefix = "\(MavlMessage.shared.appid)/\(value)/\(localId)"
        
        switch self {
        case .createGroup:
            return "\(topicPrefix)/_"
        case .oneToOne(_, let uid, _):
            return "\(topicPrefix)/\(uid)"
        case .oneToMany(_, let gid, _):
            return "\(topicPrefix)/\(gid)"
        case .vitualGroup(_, let gid, _, _):
            return "\(topicPrefix)/\(gid)"
        case .joinGroup(let gid):
            return "\(topicPrefix)/\(gid)"
        case .quitGroup(let gid):
            return "\(topicPrefix)/\(gid)"
        case .uploadToken:
            return "\(topicPrefix)/_"
        case .fetchMsgs(let from, let type, let cursor, let offset):
            return "\(topicPrefix)/\(from)/\(type.value)/\(cursor)/\(offset)"
        case .msgReceipt(let from, let to, let serverId, _):
            return "\(topicPrefix)/\(to)/\(serverId)/\(from)"
        case .msgTransparent(let to, _, _):
            return "\(topicPrefix)/\(to)"
        }
    }
    
    var payload: String {
        switch self {
        case .joinGroup, .quitGroup, .fetchMsgs:
            return ""
            
        case .createGroup(let users):
            let allUsers = users.map{ "\($0.lowercased())" }.joined(separator: ",")
            return allUsers
            
        case .oneToOne(_, _, let msg):
            return getCipherText(text: msg)
            
        case .oneToMany(_, _, let msg):
            return getCipherText(text: msg)
            
        case .vitualGroup(_, _, let users, let msg):
            let allUsers = users.map{ "\($0.lowercased())" }.joined(separator: ",")
            let cipherText = getCipherText(text: msg)
            return "\(allUsers)#\(cipherText)"
            
        case .msgReceipt(_, _, _, let state):
            return state.rawValue
            
        case .uploadToken(let deviceToken, let env, let platform, let isOn):
            let pushStrategy = isOn ? "1" : "2"
            let uploadToken = ["deviceToken": deviceToken, "env": env, "platform": platform, "deliverOnPush": pushStrategy]
            return uploadToken.toJson
            
        case .msgTransparent(_, let action, let ext):
            let payloadDict: [String: Any] = ["action": action, "ext": ext]
            return payloadDict.toJson
        }
    }
    
    var localId: String {
        switch self {
        case .createGroup, .joinGroup, .quitGroup, .uploadToken, .fetchMsgs, .msgReceipt, .msgTransparent:
            return "0"
        case .oneToOne(let localId, _, _):
            return "\(localId)"
        case .oneToMany(let localId, _, _):
            return "\(localId)"
        case .vitualGroup(let localId, _, _, _):
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
    
    private func getCipherText(text: String) -> String {
        // 发送的是文本消息, 需要加密
        guard isNeedCipher, let cipherText = EncryptUtils.encrypt(text) else {
            return text
        }
        return cipherText
    }
}

public enum FetchMessagesType {
    case one
    case more
    
    var value: Int {
        switch self {
        case .one:
            return 1
        case .more:
            return 2
        }
    }
}
