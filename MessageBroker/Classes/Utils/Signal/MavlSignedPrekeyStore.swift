//
//  MavlSignedPrekeyStore.swift
//  CCurve25519
//
//  Created by 龙格 on 2021/1/27.
//

import Foundation
import  SignalProtocol

class MavlSignedPrekeyStore: SignedPreKeyStore {
    var lastId: UInt32 = 0

    private var signedKeys = [UInt32 : Data]()
    private let MavlSignedPrekeyStoreKey = "MavlSignedPrekeyStoreKey"
    
    func signedPreKey(for id: UInt32) throws -> Data {
        guard let keys = MavlKeyStore.store(forKey: MavlSignedPrekeyStoreKey, dictKeyType: UInt32.self) else {
            throw SignalError(.invalidId, "No signed pre key for id \(id)")
        }
        signedKeys = keys
        
        guard let key = signedKeys[id] else {
            throw SignalError(.invalidId, "No signed pre key for id \(id)")
        }
        return key
    }
    
    func store(signedPreKey: Data, for id: UInt32) throws {
        signedKeys[id] = signedPreKey
        lastId = id
        
        MavlKeyStore.setStore(store: signedKeys, forKey: MavlSignedPrekeyStoreKey)
    }
    
    func containsSignedPreKey(for id: UInt32) -> Bool {
        guard let keys = MavlKeyStore.store(forKey: MavlSignedPrekeyStoreKey, dictKeyType: UInt32.self) else {
            return false
        }
        signedKeys = keys
        return signedKeys[id] != nil
    }
    
    func removeSignedPreKey(for id: UInt32) throws {
        signedKeys[id] = nil
        MavlKeyStore.setStore(store: signedKeys, forKey: MavlSignedPrekeyStoreKey)
    }
    
    func allIds() -> [UInt32] {
        guard let keys = MavlKeyStore.store(forKey: MavlSignedPrekeyStoreKey, dictKeyType: UInt32.self) else {
            return []
        }
        signedKeys = keys
        return [UInt32](signedKeys.keys)
    }
}
