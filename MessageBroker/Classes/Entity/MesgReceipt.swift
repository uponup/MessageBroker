//
//  MesgReceipt.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/12/3.
//

import Foundation

public enum ReceiptState: String {
    case sent = "sent"          // 已发送
    case received = "received"  // 已送达
    case read = "read"          // 已读
    case decryptFail = "decryptFail"    //消息解密失败
    
    public var value: Int {
        switch self {
        case .sent:
            return 1
        case .received:
            return 2
        case .read:
            return 3
        case .decryptFail:
            return 4
        }
    }
}

public protocol MesgReceipt {
    var state: ReceiptState { get set } // 消息回执状态
    var from: String { get set }        // 来自谁的回执(topic中的toPerson)
}

public struct MesgLocalReceipt: MesgReceipt {
    public var state: ReceiptState
    public var from: String
    public var msgLocalId: String       // 消息localid
}

public struct MesgRemoteReceipt: MesgReceipt {
    public var state: ReceiptState
    public var from: String
    public var msgServerId: String     // 消息serverid
}
