//
//  SignalIdentityKeyStore.swift
//  CCurve25519
//
//  Created by 龙格 on 2021/1/27.
//

import Foundation
import SignalProtocol

class MavlIdentityStore: IdentityKeyStore {
    required init(with keyPair: Data) {
        self.identityKey = keyPair
    }
    
    typealias Address = MavlAddress
    private var identityKey: Data!
    private var identities = [MavlAddress: Data]()
    
    func getIdentityKeyData() throws -> Data {
        if identityKey == nil {
            identityKey = try SignalCrypto.generateIdentityKeyPair()
        }
        return identityKey
    }
    
    func store(identityKeyData: Data) {
        identityKey = identityKeyData
    }
    
    func identity(for address: MavlAddress) throws -> Data? {
        return identities[address]
    }
    
    // 存储已经被信任的id
    func store(identity: Data?, for address: MavlAddress) throws {
        identities[address] = identity
    }
    
    init() {
    }
}
