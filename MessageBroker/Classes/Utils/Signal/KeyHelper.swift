//
//  KeyHelper.swift
//  MessageBroker
//
//  Created by 龙格 on 2021/3/8.
//

import Foundation
import SignalClient

class KeyHelper {

    static func generatePrekey(id: UInt32) -> PreKeyRecord {
        let prekey = PrivateKey.generate()
        return try! PreKeyRecord(id: id, privateKey: prekey)
    }
    
    static func generatePrekeys(start: UInt32, count: UInt32) -> [PreKeyRecord] {
        return (0..<count).enumerated().map { (_, i) -> PreKeyRecord in
            generatePrekey(id: start + i)
        }
    }
    
    static func signedPrekey(id: UInt32, keyStore: InMemorySignalProtocolStore) -> SignedPreKeyRecord {
        let signed_key = PrivateKey.generate()
        let signed_key_public: [UInt8] = signed_key.publicKey.serialize()
        let signature: [UInt8] = try! keyStore.identityKeyPair(context: NullContext()).privateKey.generateSignature(message: signed_key_public)
        let timestamp: UInt64 = UInt64(Date().timeIntervalSince1970)
        
        return try!SignedPreKeyRecord(id: id, timestamp: timestamp, privateKey: signed_key, signature: signature)
    }
}
