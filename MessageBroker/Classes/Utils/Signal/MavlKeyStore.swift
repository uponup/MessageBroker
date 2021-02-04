//
//  MavlSignalKeyStore.swift
//  CCurve25519
//
//  Created by 龙格 on 2021/1/27.
//

import Foundation
import SignalProtocol

class MavlKeyStore: KeyStore {
    typealias SessionStoreType = MavlSessionStore
    typealias Address = MavlAddress
    typealias IdentityKeyStoreType = MavlIdentityStore
    
    let identityKeyStore: MavlIdentityStore
    let preKeyStore: PreKeyStore = MavlPrekeyStore()
    let signedPreKeyStore: SignedPreKeyStore = MavlSignedPrekeyStore()
    
    let sessionStore: MavlSessionStore = MavlSessionStore()
    
    init(with keyPair: Data) {
        self.identityKeyStore = MavlIdentityStore(with: keyPair)
    }
}
