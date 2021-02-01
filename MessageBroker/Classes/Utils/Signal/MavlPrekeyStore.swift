//
//  MavlPrekeyStore.swift
//  CCurve25519
//
//  Created by 龙格 on 2021/1/27.
//

import Foundation
import SignalProtocol

class MavlPrekeyStore: PreKeyStore {
    var lastId: UInt32 = 0
    
    private var prekeys = [UInt32: Data]()
    private let MavlPrekeyStoreKey = "PreKeyStoreKey"
    
    func preKey(for id: UInt32) throws -> Data {
        guard let prekeysDict = PersistenceProvider.store(forKey: MavlPrekeyStoreKey, dictKeyType: UInt32.self) else {
            throw SignalError(.storageError, "No pre key for id \(id)")
        }
        prekeys = prekeysDict
        
        guard let key = prekeys[id] else {
            throw SignalError(.storageError, "No pre key for id \(id)")
        }
        return key
    }
    
    func store(preKey: Data, for id: UInt32) throws {
        prekeys[id] = preKey
        lastId = id
        PersistenceProvider.setStore(store: prekeys, forKey: MavlPrekeyStoreKey)
    }
    
    func containsPreKey(for id: UInt32) -> Bool {
        guard let prekeysDict = PersistenceProvider.store(forKey: MavlPrekeyStoreKey, dictKeyType: UInt32.self) else {
            return false }
        prekeys = prekeysDict
        return prekeys[id] != nil
    }
    
    func removePreKey(for id: UInt32) throws {
        prekeys[id] = nil
        PersistenceProvider.setStore(store: prekeys, forKey: MavlPrekeyStoreKey)
    }
    
    func allLocalPrekeysCount() -> Int {
        guard let prekeysDict = PersistenceProvider.store(forKey: MavlPrekeyStoreKey, dictKeyType: UInt32.self) else {
            return 0 }
        prekeys = prekeysDict
        return prekeys.count
    }
}
