//
//  SignalAddress.swift
//  CCurve25519
//
//  Created by 龙格 on 2021/1/27.
//

import SignalClient

struct MavlSignalAddress {
    let name: String
    let deviceId: UInt32
    
    var protocolAddress: ProtocolAddress? {
        return try? ProtocolAddress(name: name, deviceId: deviceId)
    }
}

extension MavlSignalAddress: Codable {
    var data: Data? {
        return try? JSONEncoder().encode(self)
    }
}

struct MavlSenderKeyName {
    let groupName: String
    let senderName: String
    let deviceId: UInt32
    
    var senderKeyName: SenderKeyName? {
        return try? SenderKeyName(groupName: groupName, senderName: senderName, deviceId: deviceId)
    }
}

extension MavlSenderKeyName: Codable {
    var data: Data? {
        return try? JSONEncoder().encode(self)
    }
}
