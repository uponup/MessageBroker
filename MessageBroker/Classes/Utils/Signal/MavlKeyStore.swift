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
    
    init() {
        self.identityKeyStore = MavlIdentityStore()
    }
}

// MARK: - 持久化
extension MavlKeyStore {
    class func store<T>(forKey key:String, dictKeyType: T.Type) -> [T: Data]? {
        guard let data = UserDefaults.object(forKey: key) as? Data,
              let sessionsDict = data.unarchiveDataToDict(keyType: dictKeyType) else {
            return nil
        }
        return sessionsDict
    }
    
    class func setStore<T>(store:[T: Data], forKey key: String) {
        UserDefaults.set(store.archivedData, forKey: key)
    }
}
