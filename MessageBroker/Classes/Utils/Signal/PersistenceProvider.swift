//
//  PersistenceProvider.swift
//  MessageBroker
//
//  Created by 龙格 on 2021/2/1.
//

import Foundation
import SignalClient


class PersistenceProvider {
  
    class func reset(forIdentifier identifier: String) {
        UserDefaults.removeObject(forKey: pkKey(forIdentifier: identifier))
        UserDefaults.removeObject(forKey: deviceIdKey(forIdentifier: identifier))
        UserDefaults.removeObject(forKey: pubkKey(forIdentifier: identifier))
        UserDefaults.removeObject(forKey: prekKey(forIdentifier: identifier))
        UserDefaults.removeObject(forKey: spkKey(forIdentifier: identifier))
        UserDefaults.removeObject(forKey: sessionKey(forIdentifier: identifier))
        UserDefaults.removeObject(forKey: skKey(forIdentifier: identifier))

    }
    
    class func signalPassport(forIdentifier identifier: String) -> (IdentityKeyPair, UInt32)? {
        guard let serialize =  UserDefaults.object(forKey: pkKey(forIdentifier: identifier)) as? [UInt8],
              let deviceId = UserDefaults.object(forKey: deviceIdKey(forIdentifier: identifier)) as? UInt32,
              let privateKey = try? IdentityKeyPair(bytes: serialize)
        else {
            return nil
        }
        return (privateKey, deviceId)
    }
    
    class func storeSignalPassport(withPrivateKey pk: IdentityKeyPair, deviceId id: UInt32, forIdentifier identifier: String) {
        UserDefaults.set(pk.serialize(), forKey: pkKey(forIdentifier: identifier))
        UserDefaults.set(id,forKey: deviceIdKey(forIdentifier: identifier))
    }
    
    // 获取publicKeys
    class func publicKeys(forIdentifier identifier: String) -> [ProtocolAddress: IdentityKey] {
        let dict: [Data: [UInt8]] = UserDefaults.object(forKey: pubkKey(forIdentifier: identifier)) as! [Data : [UInt8]]

        return Dictionary(uniqueKeysWithValues: dict.map({ (data, pubkKeys) -> (ProtocolAddress, IdentityKey)? in
            let signalAddress = try! JSONDecoder().decode(MavlSignalAddress.self, from: data)
            let ik = try! IdentityKey(bytes: pubkKeys)
            guard let add = signalAddress.protocolAddress else { return nil }
            return (add, ik)
        }).compactMap { $0 })
    }
    
    // 存储publicKeys
    class func storePublicKeys(publicKeys: [ProtocolAddress: IdentityKey], forIdentifier identifier: String) {
        let dict: [Data: [UInt8]] = Dictionary(uniqueKeysWithValues: publicKeys.map({ (data, ik) -> (Data, [UInt8]) in
            let address = MavlSignalAddress(name: data.name, deviceId: data.deviceId)
            return (address.data ?? Data(), ik.serialize())
        }))
        
        UserDefaults.set(dict, forKey: pubkKey(forIdentifier: identifier))
    }
    
    
    // 获取prekeymap
    class func prekeyMap(forIdentifier identifier: String) -> [UInt32: PreKeyRecord]{
        let dict: [UInt32: [UInt8]] = UserDefaults.object(forKey: prekKey(forIdentifier: identifier)) as! [UInt32 : [UInt8]]

        return Dictionary(uniqueKeysWithValues: dict.map({ (data, recordBytes) -> (UInt32, PreKeyRecord) in
            let record = try!PreKeyRecord(bytes: recordBytes)
            return (data, record)
        }))
    }
    
    // 存储prekeymap
    class func storePrekeyMap(prekeyMap: [UInt32: PreKeyRecord], forIdentifier identifier: String) {
        let dict: [UInt32: [UInt8]] = Dictionary(uniqueKeysWithValues: prekeyMap.map({ (id, record) -> (UInt32, [UInt8]) in
            return (id, record.serialize())
        }))
        UserDefaults.set(dict, forKey: prekKey(forIdentifier: identifier))
    }
    
    // 获取signedPreKeyMap
    class func signedPreKeyMap(forIdentifier identifier: String) -> [UInt32: SignedPreKeyRecord]{
        let dict: [UInt32: [UInt8]] = UserDefaults.object(forKey: spkKey(forIdentifier: identifier)) as! [UInt32 : [UInt8]]

        return Dictionary(uniqueKeysWithValues: dict.map({ (data, recordBytes) -> (UInt32, SignedPreKeyRecord) in
            let record = try!SignedPreKeyRecord(bytes: recordBytes)
            return (data, record)
        }))
    }
    // 存储signedPreKeyMap
    class func storeSignedPreKeyMap(spkMap: [UInt32: SignedPreKeyRecord], forIdentifier identifier: String) {
        let dict: [UInt32: [UInt8]] = Dictionary(uniqueKeysWithValues: spkMap.map({ (id, record) -> (UInt32, [UInt8]) in
            return (id, record.serialize())
        }))
        UserDefaults.set(dict, forKey: spkKey(forIdentifier: identifier))
    }
    
    // 获取sessionMap
    class func signedPreKeyMap(forIdentifier identifier: String) -> [ProtocolAddress: SessionRecord]{
        let dict: [Data: [UInt8]] = UserDefaults.object(forKey: sessionKey(forIdentifier: identifier)) as! [Data : [UInt8]]

        return Dictionary(uniqueKeysWithValues: dict.map({ (data, spkBytes) -> (ProtocolAddress, SessionRecord)? in
            let signalAddress = try! JSONDecoder().decode(MavlSignalAddress.self, from: data)
            let ik = try! SessionRecord(bytes: spkBytes)
            guard let add = signalAddress.protocolAddress else {return nil}
            return (add, ik)
        }).compactMap { $0 })
    }
    // 存储sessionMap
    class func storeSessionMap(sessionMap: [ProtocolAddress: SessionRecord], forIdentifier identifier: String) {
        let dict: [Data: [UInt8]] = Dictionary(uniqueKeysWithValues: sessionMap.map({ (data, record) -> (Data, [UInt8]) in
            let address = MavlSignalAddress(name: data.name, deviceId: data.deviceId)
            return (address.data ?? Data(), record.serialize())
        }))
        
        UserDefaults.set(dict, forKey: sessionKey(forIdentifier: identifier))
    }
    
    // 获取senderKeyMap
    class func senderKeyMap(forIdentifier identifier: String) -> [SenderKeyName: SenderKeyRecord]{
        let dict: [Data: [UInt8]] = UserDefaults.object(forKey: skKey(forIdentifier: identifier)) as! [Data : [UInt8]]

        return Dictionary(uniqueKeysWithValues: dict.map({ (data, skrBytes) -> (SenderKeyName, SenderKeyRecord)? in
            let skn = try! JSONDecoder().decode(MavlSenderKeyName.self, from: data)
            let ik = try! SenderKeyRecord(bytes: skrBytes)
            guard let add = skn.senderKeyName else {return nil}
            return (add, ik)
        }).compactMap { $0 })
    }
    
    // 存储senderKeyMap
    // warnings: 此处MavlSenderKeyName在Encode的时候，将参数groupName用groupId代替
    class func storeSenderKeyMap(skMap: [SenderKeyName: SenderKeyRecord], forIdentifier identifier: String) {
        let dict: [Data: [UInt8]] = Dictionary(uniqueKeysWithValues: skMap.map({ (data, record) -> (Data, [UInt8]) in
            
            let address = MavlSenderKeyName(groupName: data.groupId, senderName: data.senderName, deviceId: data.senderDeviceId)
            return (address.data ?? Data(), record.serialize())
        }))
        
        UserDefaults.set(dict, forKey: skKey(forIdentifier: identifier))
    }
    
    
    // Generate Persistence Key
    private class func deviceIdKey(forIdentifier identifier: String) -> String {
        return "DeviceId_\(identifier)"
    }
    
    private class func pkKey(forIdentifier identifier: String) -> String {
        return "PrivateKey_\(identifier)"
    }
    
    private class func pubkKey(forIdentifier identifier: String) -> String {
        return "PublicKeys_\(identifier)"
    }
    
    private class func prekKey(forIdentifier identifier: String) -> String {
        return "PrekeyMap_\(identifier)"
    }
    
    private class func spkKey(forIdentifier identifier: String) -> String {
        return "SignedPreKeyMap_\(identifier)"
    }
    
    private class func sessionKey(forIdentifier identifier: String) -> String {
        return "SessionMap_\(identifier)"
    }
    
    private class func skKey(forIdentifier identifier: String) -> String {
        return "SenderKeyMap_\(identifier)"
    }
}

extension PersistenceProvider {
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
        存储Signal密钥对
     */
    class func storeKeyPair(with keypair: Data) {
        let key = generatePersistenceKey(forKey: "SignalKeyPair")
        UserDefaults.set(keypair,forKey: key)
    }
    
    /**
        获取密钥对
     */
    class func getKeyPair() -> Data? {
        let key = generatePersistenceKey(forKey: "SignalKeyPair")
        return UserDefaults.object(forKey: key) as? Data
    }
    
    private class func generatePersistenceKey(forKey key: String) -> String {
        guard let passport = MavlMessage.shared.passport else {
            return key
        }
        return "\(key)_\(passport.uid.value)"
    }
}
