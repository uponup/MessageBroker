//
//  MavlSignedPrekeyStore.swift
//  CCurve25519
//
//  Created by 龙格 on 2021/1/27.
//

import Foundation
import  SignalProtocol

class MavlSignedPrekeyStore: SignedPreKeyStore {
    private var signedKeys = [UInt32 : Data]()
    var lastId: UInt32 = 0

    func signedPreKey(for id: UInt32) throws -> Data {
        guard let key = signedKeys[id] else {
            throw SignalError(.invalidId, "No signed pre key for id \(id)")
        }
        return key
    }
    
    func store(signedPreKey: Data, for id: UInt32) throws {
        signedKeys[id] = signedPreKey
        lastId = id
    }
    
    func containsSignedPreKey(for id: UInt32) -> Bool {
        return signedKeys[id] != nil
    }
    
    func removeSignedPreKey(for id: UInt32) throws {
        signedKeys[id] = nil
    }
    
    func allIds() -> [UInt32] {
        return [UInt32](signedKeys.keys)
    }
}
