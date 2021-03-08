//
//  KeyHelper.swift
//  MessageBroker
//
//  Created by 龙格 on 2021/3/8.
//

import Foundation
import SignalClient

class KeyHelper {
    static func generateIdnetityKeyPair() -> IdentityKeyPair {
        let keyPair = IdentityKeyPair.generate()
        return keyPair
    }
    
    static func generateRegistrationId() -> Int32 {
        return 0
    }
    
    static func generatePreKeys(forCount count: Int) -> [PreKeyRecord] {
        var records: [PreKeyRecord] = []
        for _ in 0..<count {
            do {
                let prekey = try PreKeyRecord(bytes: PrivateKey.generate().publicKey.serialize())
                records.append(prekey)
            } catch _ {}
        }
        return records
    }
    
    static func generateSignedPrekey() throws -> SignedPreKeyRecord {
        return try SignedPreKeyRecord(bytes: PrivateKey.generate().publicKey.serialize())
    }
    
    static func generateSignature(forSignedPrekey spk: [UInt8], bobStore: SignalProtocolStore) -> [UInt8] {
        return try!bobStore.identityKeyPair(context: NullContext()).privateKey.generateSignature(message:spk)
    }
}
