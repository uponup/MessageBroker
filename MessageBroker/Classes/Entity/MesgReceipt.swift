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
    
    public var value: Int {
        switch self {
        case .sent:
            return 1
        case .received:
            return 2
        case .read:
            return 3
        }
    }
}

public protocol MesgReceipt {
    var state: ReceiptState { get set } // 消息回执状态
    var from: String { get set }        // 来自谁的回执(topic中的toPerson)
}

@objcMembers public class MesgServerReceipt: NSObject, MesgReceipt {
    public var state: ReceiptState
    public var from: String
    public var msgLocalId: String       // 消息localid
    
    init(state: ReceiptState, from: String, msgLocalId: String) {
        self.state = .received
        self.from = ""
        self.msgLocalId = ""
    }
}

@objcMembers public class MesgRemoteReceipt: NSObject, MesgReceipt {
    public var state: ReceiptState
    public var from: String
    public var msgServerId: String     // 消息serverid
    
    init(state: ReceiptState, from: String, msgServerId: String) {
        self.state = .received
        self.from = ""
        self.msgServerId = ""
    }
}
