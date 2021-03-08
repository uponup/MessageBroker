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
    
    private var publicKeys: [ProtocolAddress: IdentityKey] = [:]
    private var prekeyMap: [UInt32: PreKeyRecord] = [:]
    private var signedPrekeyMap: [UInt32: SignedPreKeyRecord] = [:]
    private var sessionMap: [ProtocolAddress: SessionRecord] = [:]
    private var senderKeyMap: [SenderKeyName: SenderKeyRecord] = [:]
    
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
    
    /**
     删除某个id对应的store
     */
    func resetStore(forIdentifier identifier: String) {
        PersistenceProvider.reset(forIdentifier: identifier)
    }
    
    func isExistSession(for address: ProtocolAddress) -> Bool {
        if let _ = sessionMap[address] {
            return true
        }else {
            return false
        }
    }
    
    func prekeysCount() -> Int {
        return prekeyMap.count
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
        if publicKeys.updateValue(identity, forKey: address) == nil {
            return false; // newly created
        } else {
            PersistenceProvider.storePublicKeys(publicKeys: publicKeys, forIdentifier: identifier)
            return true
        }
    }

    public func isTrustedIdentity(_ identity: IdentityKey, for address: ProtocolAddress, direction: Direction, context: StoreContext) throws -> Bool {
        var ret: Bool
        if let pk = publicKeys[address] {
            ret = pk == identity
        } else {
            ret = true // tofu
        }
        
        if ret {
            PersistenceProvider.storePublicKeys(publicKeys: publicKeys, forIdentifier: identifier)
        }
        return ret
    }

    public func identity(for address: ProtocolAddress, context: StoreContext) throws -> IdentityKey? {
        return publicKeys[address]
    }

    // MARK: - PreKeyStore
    public func loadPreKey(id: UInt32, context: StoreContext) throws -> PreKeyRecord {
        if let record = prekeyMap[id] {
            return record
        } else {
            throw SignalError.invalidKeyIdentifier("no prekey with this identifier")
        }
    }

    public func storePreKey(_ record: PreKeyRecord, id: UInt32, context: StoreContext) throws {
        prekeyMap[id] = record
        
        PersistenceProvider.storePrekeyMap(prekeyMap: prekeyMap, forIdentifier: identifier)
    }

    public func removePreKey(id: UInt32, context: StoreContext) throws {
        prekeyMap.removeValue(forKey: id)
        
        PersistenceProvider.storePrekeyMap(prekeyMap: prekeyMap, forIdentifier: identifier)
    }

    // MARK: - SignedPreKeyStore
    public func loadSignedPreKey(id: UInt32, context: StoreContext) throws -> SignedPreKeyRecord {
        if let record = signedPrekeyMap[id] {
            return record
        } else {
            throw SignalError.invalidKeyIdentifier("no signed prekey with this identifier")
        }
    }

    public func storeSignedPreKey(_ record: SignedPreKeyRecord, id: UInt32, context: StoreContext) throws {
        signedPrekeyMap[id] = record
        
        PersistenceProvider.storeSignedPreKeyMap(spkMap: signedPrekeyMap, forIdentifier: identifier)
    }

    // MARK: - SessionStore
    public func loadSession(for address: ProtocolAddress, context: StoreContext) throws -> SessionRecord? {
        return sessionMap[address]
    }

    public func storeSession(_ record: SessionRecord, for address: ProtocolAddress, context: StoreContext) throws {
        sessionMap[address] = record
        
        PersistenceProvider.storeSessionMap(sessionMap: sessionMap, forIdentifier: identifier)
    }

    // MARK: - SenderKeyStore
    public func storeSenderKey(name: SenderKeyName, record: SenderKeyRecord, context: StoreContext) throws {
        senderKeyMap[name] = record
        
        PersistenceProvider.storeSenderKeyMap(skMap: senderKeyMap, forIdentifier: identifier)
    }

    public func loadSenderKey(name: SenderKeyName, context: StoreContext) throws -> SenderKeyRecord? {
        return senderKeyMap[name]
    }
}
