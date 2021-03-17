//
//  SignalProtocolStore.swift
//  MessageBroker
//
//  Created by 龙格 on 2021/3/5.
//

import Foundation
import SignalClient

struct NullContext: StoreContext {
    init() {}
}

class SignalProtocolStore {
    private var privateKey: IdentityKeyPair
    private var deviceId: UInt32
    private var identifier: String
    
    // 每个用户都有对应的唯一标识符，暂且设定为用户uid
    init(withIdentifier identifier: String) {
        self.identifier = identifier
        if let passport = PersistenceProvider.signalPassport(forIdentifier: identifier) {
            (privateKey, deviceId) = passport
        }else {
            privateKey = IdentityKeyPair.generate()
            deviceId = 0    // 暂定deviceId为0，Signal是基于MessageBroker的，在MB中没有保存用户的设备信息，所以Signal曾无法获取用户准确的deviceId，后续遇到多设备的新需求的时候在考虑
            PersistenceProvider.storeSignalPassport(withPrivateKey: privateKey, deviceId: deviceId, forIdentifier: identifier)
        }
    }
    
    // 批量存储prekey
    func storePrekeys(keys: [PreKeyRecord]) {
        for record in keys {
            storePrekey(record: record)
        }
    }
    
    // 存储spk
    func storeSignedPrekey(spk: SignedPreKeyRecord) {
        try! storeSignedPreKey(spk, id: spk.id, context: NullContext())
    }
}

// 持久化
extension SignalProtocolStore {
    
    // ik
    func storeIdentityKey(pubKey: IdentityKey, forKey key: ProtocolAddress) -> Bool {
        UserDefaults.set(pubKey.serialize(), forKey: "\(key.hashValue)")
        return true
    }
    
    func getIdentityKey(for key: ProtocolAddress) -> IdentityKey? {
        let bytes: [UInt8] = UserDefaults.object(forKey: "\(key.hashValue)") as? [UInt8] ?? []
        return try? IdentityKey(bytes: bytes)
    }
    
    // prekey
    func storePrekey(record: PreKeyRecord) {
        UserDefaults.set(record.serialize(), forKey: "\(record.id)")
    }
    
    func removePrekey(for id: UInt32) {
        UserDefaults.removeObject(forKey: "\(id)")
    }
    
    func getPrekey(for id: UInt32) throws -> PreKeyRecord? {
        let bytes = UserDefaults.object(forKey: "\(id)") as? [UInt8] ?? []
        return try PreKeyRecord(bytes: bytes)
    }
    
    // spk
    func _storeSignedPrekey(spk: SignedPreKeyRecord) {
        UserDefaults.set(spk.serialize(), forKey: "\(spk.id)")
    }
    
    func getSignedPrekey(for id: UInt32) throws -> SignedPreKeyRecord {
        let bytes = UserDefaults.object(forKey: "\(id)") as? [UInt8] ?? []
        return try SignedPreKeyRecord(bytes: bytes)
    }
    
    // session
    func storeSession(session: SessionRecord, for address: ProtocolAddress) {
        UserDefaults.set(session.serialize(), forKey: "\(address.hashValue)")
    }
    
    func getSession(for address: ProtocolAddress) throws -> SessionRecord {
        let bytes = UserDefaults.object(forKey: "\(address.hashValue)") as? [UInt8] ?? []
        return try SessionRecord(bytes: bytes)
    }
    
    // senderkey
    func storeSenderKey(record: SenderKeyRecord, for sender: SenderKeyName) {
        UserDefaults.set(record.serialize(), forKey: "\(sender.groupId)-\(sender.senderName)-\(sender.senderDeviceId)")
    }
    
    func getSenderKey(for sender: SenderKeyName) throws -> SenderKeyRecord {
        let bytes = UserDefaults.object(forKey: "\(sender.groupId)-\(sender.senderName)-\(sender.senderDeviceId)") as? [UInt8] ?? []
        return try SenderKeyRecord(bytes: bytes)
    }
}

extension SignalProtocolStore: IdentityKeyStore, PreKeyStore, SignedPreKeyStore, SessionStore, SenderKeyStore {
    
    // MARK: - IdentityKeyStore
    public func identityKeyPair(context: StoreContext) throws -> IdentityKeyPair {
        return privateKey
    }
    
    public func localRegistrationId(context: StoreContext) throws -> UInt32 {
        return deviceId
    }
    
    public func saveIdentity(_ identity: IdentityKey, for address: ProtocolAddress, context: StoreContext) throws -> Bool {
        storeIdentityKey(pubKey: identity, forKey: address)
    }

    public func isTrustedIdentity(_ identity: IdentityKey, for address: ProtocolAddress, direction: Direction, context: StoreContext) throws -> Bool {
        var ret: Bool
        if let pk = getIdentityKey(for: address) {
            ret = pk == identity
        } else {
            ret = true
        }
        return ret
    }

    public func identity(for address: ProtocolAddress, context: StoreContext) throws -> IdentityKey? {
        return getIdentityKey(for: address)
    }

    // MARK: - PreKeyStore
    public func loadPreKey(id: UInt32, context: StoreContext) throws -> PreKeyRecord {
        if let prekey = try? getPrekey(for: id) {
            return prekey
        }else {
            throw SignalError.invalidKey("no such prekey")
        }
    }

    public func storePreKey(_ record: PreKeyRecord, id: UInt32, context: StoreContext) throws {
        storePrekey(record: record)
    }

    public func removePreKey(id: UInt32, context: StoreContext) throws {
        removePrekey(for: id)
    }

    // MARK: - SignedPreKeyStore
    public func loadSignedPreKey(id: UInt32, context: StoreContext) throws -> SignedPreKeyRecord {
        if let record = try? getSignedPrekey(for: id) {
            return record
        } else {
            throw SignalError.invalidKeyIdentifier("no signed prekey with this identifier")
        }
    }

    public func storeSignedPreKey(_ record: SignedPreKeyRecord, id: UInt32, context: StoreContext) throws {
        _storeSignedPrekey(spk: record)
    }

    // MARK: - SessionStore
    public func loadSession(for address: ProtocolAddress, context: StoreContext) throws -> SessionRecord? {
        try getSession(for: address)
    }

    public func storeSession(_ record: SessionRecord, for address: ProtocolAddress, context: StoreContext) throws {
        storeSession(session: record, for: address)
    }

    // MARK: - SenderKeyStore
    public func storeSenderKey(name: SenderKeyName, record: SenderKeyRecord, context: StoreContext) throws {
        storeSenderKey(record: record, for: name)
    }

    public func loadSenderKey(name: SenderKeyName, context: StoreContext) throws -> SenderKeyRecord? {
        try getSenderKey(for: name)
    }
}
