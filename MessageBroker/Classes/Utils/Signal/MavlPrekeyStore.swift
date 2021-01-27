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
    
    func preKey(for id: UInt32) throws -> Data {
        guard let key = prekeys[id] else {
            throw SignalError(.storageError, "No pre key for id \(id)")
        }
        return key
    }
    
    func store(preKey: Data, for id: UInt32) throws {
        prekeys[id] = preKey
        lastId = id
    }
    
    func containsPreKey(for id: UInt32) -> Bool {
        return prekeys[id] != nil
    }
    
    func removePreKey(for id: UInt32) throws {
        prekeys[id] = nil
    }
    
}
