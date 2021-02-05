//
//  SignalEncryptUtils.swift
//  MessageBroker
//
//  Created by 龙格 on 2021/1/27.
//

import Foundation
import SignalProtocol

struct SignalUtils {
    static let `default` = SignalUtils()
    private let maxPrekeysCount = 16
    private var aliceStore: MavlKeyStore?
    
    init() {
        // 公钥仅生成一次
        let _ = UserDefaults.executeOnce(withKey: "install_signal") {
            do {
                let data = try SignalCrypto.generateIdentityKeyPair()
                PersistenceProvider.storeKeyPair(with: data)
            } catch let e {
                print(e)
            }
        }
        
        guard let data = PersistenceProvider.getKeyPair() else { return }
        aliceStore = MavlKeyStore(with: data)
    }
    
    func isExistSession(to: String) -> Bool {
        let address = MavlAddress(identifier: to)
        guard let _ = aliceStore?.sessionStore.containsSession(for: address) else {
            return false
        }
        return true
    }
    
    func createSignalSession(bundleStr: String, to: String) throws -> Bool {
        let address = MavlAddress(identifier: to)
        resetAliceStore(forAddress: address)
        
        guard let data = bundleStr.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers),
              let encodeBundleDict = json as? [String: String] else {
            throw MavlSignalError(type: .initialFailed)
        }
        
        let decodeBundleDict: [String: Data] = encodeBundleDict.mapValues {
            Data(base64Encoded: $0) ?? Data()
        }
        
        guard let prekey = decodeBundleDict["prekey"] else {
            print("没有获取到prekey")
            throw MavlSignalError(type: .initialFailed)
        }
        
        guard let alice = aliceStore else {
            print("alice没有初始化")
            throw MavlSignalError(type: .initialFailed)
        }
        
        let session = SessionCipher(store: alice, remoteAddress: address)
        do {
            let sessionPrekeyBundle = try SessionPreKeyBundle(preKey: prekey, signedPreKey: decodeBundleDict["signedPrekey"]!, identityKey: decodeBundleDict["identityKey"]!)
            try session.process(preKeyBundle: sessionPrekeyBundle)
            
            return true
        } catch let e {
            print("对方公钥校验失败: \(e.localizedDescription)")
            // 校验失败
            throw MavlSignalError(type: .initialFailed)
        }
    }
    
    func generatePublicBundle() throws -> [String: Any] {
        guard let alice = aliceStore else {
            throw MavlSignalError(type: .initialFailed)
        }
        // 小于某个阈值才上传
        guard let prekeyStore = alice.preKeyStore as? MavlPrekeyStore, prekeyStore.allLocalPrekeysCount() < maxPrekeysCount/2 else {
            throw MavlSignalError(type: .prekeysExists)
        }
        do {
            let identityKey: Data = try alice.identityKeyStore.getIdentityKeyPublicData()
            let prekeys: [Data] = try alice.createPreKeys(count: maxPrekeysCount)
            let signedPrekey: Data = try alice.updateSignedPrekey()
            
            let uploadDict: [String: Any] = [
                "identityKey": identityKey.base64EncodedString(),
                "prekeys": prekeys.map{ $0.base64EncodedString()},
                "signedPrekey": signedPrekey.base64EncodedString()
            ]
            return uploadDict
        } catch  {
            throw MavlSignalError(type: .initialFailed)
        }
    }
    
    // 将Signal加密后密文的protoData采用base64编码后返回
    func encrypt(_ data: String, _ to: String) throws -> String {
        guard let alice = aliceStore else {
            throw MavlSignalError(type: .initialFailed)
        }
        
        let address = MavlAddress(identifier: to)
        guard let _ = alice.identityKeyStore.identity(for: address) else {
            throw MavlSignalError(type: .untrustIdentityKey)
        }
        
        guard let messageData = data.data(using: .utf8) else {
            throw MavlSignalError(type: .invalidUtf8)
        }
        
        do {
            let session = SessionCipher(store: alice, remoteAddress: address)
            let protoData = try session.encrypt(messageData).protoData()
            return protoData.base64EncodedString()
        } catch let err {
            throw err
        }
    }
    
    // 先用base64解码，获取得到protoData，然后构造CipherTextMessage用来解密
    func decrypt(_ data: String, _ from: String) throws -> String {
        guard let alice = aliceStore else {
            throw MavlSignalError(type: .initialFailed)
        }
        
        let address = MavlAddress(identifier: from)
        
        guard let messageData = Data(base64Encoded: data) else {
            throw MavlSignalError(type: .invalidBase64)
        }
        do {
            let session = SessionCipher(store: alice, remoteAddress: address)
            let cipher = try CipherTextMessage(from: messageData)
            let decryptedMessageData = try session.decrypt(cipher)
            
            guard let originText = String(data: decryptedMessageData, encoding: .utf8) else {
                throw MavlSignalError(type: .invalidUtf8)
            }
            return originText
        } catch let signalErr as SignalError {
            if signalErr.type == .untrustedIdentity {
                // 不受信任的公钥，本地公钥和对方公钥不一致，需要删除本地signal缓存
                resetAliceStore(forAddress: address)
                
                throw MavlSignalError(type: .untrustIdentityKey)
            }else if signalErr.type == .invalidMessage {
                // 主要是mac校验有问题
                resetAliceStore(forAddress: address)
                
                throw MavlSignalError(type: .invalidMessage)
            }
            throw MavlSignalError(type: .other)
        }
    }
    
    private func resetAliceStore(forAddress address: MavlAddress) {
        guard let alice = aliceStore else { return }

        alice.sessionStore.deleteSession(for: address)
        alice.identityKeyStore.store(identity: nil, for: address)
    }
}
