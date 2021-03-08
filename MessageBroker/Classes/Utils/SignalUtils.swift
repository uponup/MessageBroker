//
//  SignalEncryptUtils.swift
//  MessageBroker
//
//  Created by 龙格 on 2021/1/27.
//

import Foundation
import SignalClient

struct SignalUtils {
    static let `default` = SignalUtils()
    private let maxPrekeysCount = 16
    private var aliceStore: SignalProtocolStore?
    
    init() {
        guard let passport = MavlMessage.shared.passport else {
            print("===> 初始化失败")
            return
        }
        aliceStore = SignalProtocolStore(withIdentifier: passport.uid)
    }
    
    func isExistSession(to: String) -> Bool {
        guard let address = try?ProtocolAddress(name: to, deviceId: 0), let isContain = aliceStore?.isExistSession(for: address), isContain else {
            return false
        }
        return true
    }
    
    func createSignalSession(bundleStr: String, to: String) throws -> Bool {
//        resetAliceStore(forAddress: address)
        
        guard let data = bundleStr.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers),
              let encodeBundleDict = json as? [String: String] else {
            throw MavlSignalError(type: .initialFailed)
        }
        
        let decodeBundleDict: [String: [UInt8]] = encodeBundleDict.mapValues {
            let publicKey = Data(base64Encoded: $0) ?? Data()
            return publicKey.bytes
        }
        
        guard let prekeyBytes = decodeBundleDict["prekey"] else {
            print("没有获取到prekey")
            throw MavlSignalError(type: .initialFailed)
        }
        
        guard let alice = aliceStore else {
            print("alice没有初始化")
            throw MavlSignalError(type: .initialFailed)
        }
            
        let bobStore = SignalProtocolStore(withIdentifier: to)
        let bobAddress = try! ProtocolAddress(name: to, deviceId: 0)
        
        do {
            let ik = try IdentityKey(bytes: decodeBundleDict["identityKey"]!)
            let prekey = try PreKeyRecord(bytes: prekeyBytes)
            let spk = try SignedPreKeyRecord(bytes: decodeBundleDict["signedPrekey"]!)
            let spkSignature = KeyHelper.generateSignature(forSignedPrekey: decodeBundleDict["signedPrekey"]!, bobStore: bobStore)

            let prekeyBundle = try PreKeyBundle(registrationId: 0, deviceId: 0, prekeyId: prekey.id, prekey: prekey.publicKey, signedPrekeyId: spk.id, signedPrekey: spk.publicKey, signedPrekeySignature: spkSignature, identity: ik)
            try processPreKeyBundle(prekeyBundle, for: bobAddress, sessionStore: alice, identityStore: alice, context: NullContext())
            
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
        guard alice.prekeysCount() < maxPrekeysCount/2 else {
            throw MavlSignalError(type: .prekeysExists)
        }
        do {
            let identityKey: [UInt8] = try alice.identityKeyPair(context: NullContext()).identityKey.serialize()
            let prekeys: [[UInt8]] = KeyHelper.generatePreKeys(forCount: maxPrekeysCount).map{$0.serialize()}
            let signedPrekey: [UInt8] = try KeyHelper.generateSignedPrekey().serialize()

            let uploadDict: [String: Any] = [
                "identityKey": Data(bytes: identityKey, count: identityKey.count).base64EncodedString(),
                "prekeys": prekeys.map{ Data(bytes: $0, count: $0.count).base64EncodedString() },
                "signedPrekey": Data(bytes: signedPrekey, count: signedPrekey.count)
            ]
            return uploadDict
        } catch  {
            throw MavlSignalError(type: .initialFailed)
        }
    }
    
    // 将Signal加密后密文的protoData采用base64编码后返回
    func encrypt(_ originText: String, _ to: String) throws -> String {
        guard let alice = aliceStore else {
            throw MavlSignalError(type: .initialFailed)
        }
        
        do {
            let bobAddress = try ProtocolAddress(name: to, deviceId: 0)
            let cipherBytes = try signalEncrypt(message: originText.bytes, for: bobAddress, sessionStore: alice, identityStore: alice, context: NullContext()).serialize()
            return Data(bytes: cipherBytes, count: cipherBytes.count).base64EncodedString()
        } catch let err {
            throw err
        }
    }
    
    // 先用base64解码，获取得到protoData，然后构造CipherTextMessage用来解密
    func decrypt(_ data: String, _ from: String) throws -> String {
        guard let alice = aliceStore else {
            throw MavlSignalError(type: .initialFailed)
        }
                
        guard let messageData = Data(base64Encoded: data) else {
            throw MavlSignalError(type: .invalidBase64)
        }
        
        guard let bobAddress = try? ProtocolAddress(name: from, deviceId: 0) else {
            throw MavlSignalError(type: .other)
        }
        
        if let signalMessage = try? SignalMessage(bytes: messageData.bytes) {
            let originTextBytes = try signalDecrypt(message: signalMessage, from: bobAddress, sessionStore: alice, identityStore: alice, context: NullContext())
            guard let originText = String(bytes: originTextBytes, encoding: .utf8) else {
                throw MavlSignalError(type: .invalidUtf8)
            }
            return originText
        }else if let prekeySignalMessage = try? PreKeySignalMessage(bytes: messageData.bytes) {
            let originTextBytes = try signalDecryptPreKey(message: prekeySignalMessage, from: bobAddress, sessionStore: alice, identityStore: alice, preKeyStore: alice, signedPreKeyStore: alice, context: NullContext())
            guard let originText = String(bytes: originTextBytes, encoding: .utf8) else {
                throw MavlSignalError(type: .invalidUtf8)
            }
            return originText
        }else {
            throw MavlSignalError(type: .other)
        }

    }
    
    private func resetAliceStore(forAddress address: MavlSignalAddress) {
        guard let alice = aliceStore else { return }

//        alice.sessionStore.deleteSession(for: address)
//        alice.identityKeyStore.store(identity: nil, for: address)
    }
}
