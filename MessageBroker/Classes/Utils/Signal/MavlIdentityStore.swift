//
//  SignalIdentityKeyStore.swift
//  CCurve25519
//
//  Created by 龙格 on 2021/1/27.
//

import Foundation
import SignalProtocol

class MavlIdentityStore: IdentityKeyStore {
    typealias Address = MavlAddress
    
    private var identityKey: Data!
    private var identities = [Address: Data]()
    private let MavlIdentityStoreKey = "MavlIdentityStoreKey"
    
    required init(with keyPair: Data) {
        self.identityKey = keyPair
    }
    
    func getIdentityKeyData() throws -> Data {
        if identityKey == nil {
            identityKey = try SignalCrypto.generateIdentityKeyPair()
        }
        return identityKey
    }
    
    func identity(for address: Address) throws -> Data? {
        guard let ids = MavlKeyStore.store(forKey: MavlIdentityStoreKey, dictKeyType: Address.self) else {
            return nil
        }
        identities = ids
        return identities[address]
    }
    
    // 存储已经被信任的id
    func store(identity: Data?, for address: Address) throws {
        identities[address] = identity
        MavlKeyStore.setStore(store: identities, forKey: MavlIdentityStoreKey)
    }
    
    init() {
    }
}
