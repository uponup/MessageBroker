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
    class func store<T: Codable>(forKey key:String, dictKeyType: T.Type) -> [T: Data]? {
        guard let data = UserDefaults.object(forKey: key) as? Data,
              let dict = data.unarchiveDataToDict(keyType: Data.self) else {
            return nil
        }
        let sessionsDict = Dictionary(uniqueKeysWithValues: dict.map({ (sessionKey, value) -> (T, Data) in
            let obj = try!JSONDecoder().decode(T.self, from: sessionKey)
            return (obj, value)
        }))
        return sessionsDict
    }
    
    class func store<T: UnsignedInteger>(forKey key:String, dictKeyType: T.Type) -> [T: Data]? {
        guard let data = UserDefaults.object(forKey: key) as? Data,
              let dict = data.unarchiveDataToDict(keyType: T.self) else {
            return nil
        }
        return dict
    }
    
    class func setStore<T: UnsignedInteger>(store:[T: Data], forKey key: String) {
        UserDefaults.set(store.archivedData, forKey: key)
    }
    
    class func setStore<T: Codable>(store:[T: Data], forKey key: String) {
        let dict = Dictionary(uniqueKeysWithValues: store.map({ (sessionKey, value) -> (Data, Data) in
            let data = try!JSONEncoder().encode(sessionKey)
            return (data, value)
        }))
        UserDefaults.set(dict.archivedData, forKey: key)
    }
}
