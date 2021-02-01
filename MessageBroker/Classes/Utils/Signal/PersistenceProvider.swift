//
//  PersistenceProvider.swift
//  MessageBroker
//
//  Created by 龙格 on 2021/2/1.
//

import Foundation

class PersistenceProvider {
    class func store<T: Codable>(forKey key:String, dictKeyType: T.Type) -> [T: Data]? {
        guard let data = UserDefaults.object(forKey: generatePersistenceKey(forKey: key)) as? Data,
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
        guard let data = UserDefaults.object(forKey: generatePersistenceKey(forKey: key)) as? Data,
              let dict = data.unarchiveDataToDict(keyType: T.self) else {
            return nil
        }
        return dict
    }
    
    class func setStore<T: UnsignedInteger>(store:[T: Data], forKey key: String) {
        UserDefaults.set(store.archivedData, forKey: generatePersistenceKey(forKey: key))
    }
    
    class func setStore<T: Codable>(store:[T: Data], forKey key: String) {
        let dict = Dictionary(uniqueKeysWithValues: store.map({ (sessionKey, value) -> (Data, Data) in
            let data = try!JSONEncoder().encode(sessionKey)
            return (data, value)
        }))
        UserDefaults.set(dict.archivedData, forKey: generatePersistenceKey(forKey: key))
    }
    
    /**
        设备绑定Signal的个数
     */
    class func signalCountForDevice() -> Int {
        return UserDefaults.standard.dictionaryRepresentation().keys.filter {
            $0.hasPrefix("MavlSessionStoreKey")
        }.count
    }
    
    /**
        查看是否绑定了该设备
     */
    class func isBindDevice(forUser imAccount: String) -> Bool {
        return UserDefaults.standard.data(forKey: "MavlSessionStoreKey_\(imAccount)") != nil
    }
    
    private class func generatePersistenceKey(forKey key: String) -> String {
        guard let passport = MavlMessage.shared.passport else {
            return key
        }
        return "\(key)_\(passport.uid.value)"
    }
}
