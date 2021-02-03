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
    private let aliceStore = MavlKeyStore()
    
    init() {
        // 公钥仅生成一次
        let _ = UserDefaults.executeOnce(withKey: "install_signal") {
            do {
                let data = try SignalCrypto.generateIdentityKeyPair()
                print(Array(data))
            } catch let e {
                print(e)
            }
        }
    }
    
    func isExistSession(to: String) -> Bool {
        let address = MavlAddress(identifier: to)
        guard let _ = try?aliceStore.identityKeyStore.identity(for: address) else {
            return false
        }
        return true
    }
    
    func createSignalSession(bundleStr: String, to: String) {
        let address = MavlAddress(identifier: to)
        
        guard let data = bundleStr.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers),
              let encodeBundleDict = json as? [String: String] else {
            return
        }
        
        let decodeBundleDict: [String: Data] = encodeBundleDict.mapValues {
            Data(base64Encoded: $0) ?? Data()
        }
        
        guard let prekey = decodeBundleDict["prekey"] else {
            print("没有获取到prekey")
            return
        }
        
        let session = SessionCipher(store: aliceStore, remoteAddress: address)
        do {
            let sessionPrekeyBundle = try SessionPreKeyBundle(preKey: prekey, signedPreKey: decodeBundleDict["signedPrekey"]!, identityKey: decodeBundleDict["identityKey"]!)
            try session.process(preKeyBundle: sessionPrekeyBundle)
            
            // 校验成功，可以发送加密消息
            NotificationCenter.default.post(name: .signalLoad, object: ["to": to, "ret": true])
        } catch let e {
            print("对方公钥校验失败: \(e.localizedDescription)")
            // 校验失败
            NotificationCenter.default.post(name: .signalLoad, object: ["to": to, "ret": false])
        }
    }
    
    func generatePublicBundle() throws -> [String: Any] {
        // 小于某个阈值才上传
//        guard let prekeyStore = aliceStore.preKeyStore as? MavlPrekeyStore, prekeyStore.allLocalPrekeysCount() < maxPrekeysCount/2 else {
//            throw NSError(domain: "com.mavl.signal", code: -2004, userInfo: ["msg": "prekeys足够用，不需要上传"])
//        }
        do {
            let identityKey: Data = try aliceStore.identityKeyStore.getIdentityKeyPublicData()
            let prekeys: [Data] = try aliceStore.createPreKeys(count: maxPrekeysCount/2)
            let signedPrekey: Data = try aliceStore.updateSignedPrekey()
            
            let uploadDict: [String: Any] = [
                "identityKey": identityKey.base64EncodedString(),
                "prekeys": prekeys.map{ $0.base64EncodedString()},
                "signedPrekey": signedPrekey.base64EncodedString()
            ]
            return uploadDict
        } catch  {
            throw NSError(domain: "com.mavl.signal", code: -2000, userInfo: ["msg": "初始化公钥失败"])
        }
    }
    
    // 将Signal加密后密文的protoData采用base64编码后返回
    func encrypt(_ data: String, _ to: String) throws -> String {
        let address = MavlAddress(identifier: to)
        guard let _ = try? aliceStore.identityKeyStore.identity(for: address) else {
            throw NSError(domain: "com.mavl.signal", code: -2001, userInfo: ["msg": "缺少必要session，无法加密"])
        }
        
        guard let messageData = data.data(using: .utf8) else {
            throw NSError(domain: "com.mavl.signal", code: -2003, userInfo: ["msg": "初始消息有问题，无法转成Data"])
        }
        
        do {
            let session = SessionCipher(store: aliceStore, remoteAddress: address)
            let protoData = try session.encrypt(messageData).protoData()
            return protoData.base64EncodedString()
        } catch let err {
            throw err
        }
    }
    
    // 先用base64解码，获取得到protoData，然后构造CipherTextMessage用来解密
    func decrypt(_ data: String, _ from: String) throws -> String {
        let address = MavlAddress(identifier: from)
        
        guard let messageData = Data(base64Encoded: data) else {
            throw NSError(domain: "com.mavl.signal", code: -2004, userInfo: ["msg": "base64解码失败"])
        }
        do {
            let session = SessionCipher(store: aliceStore, remoteAddress: address)
            let cipher = try CipherTextMessage(from: messageData)
            let decryptedMessageData = try session.decrypt(cipher)
            
            guard let originText = String(data: decryptedMessageData, encoding: .utf8) else {
                throw NSError(domain: "com.mavl.signal", code: -2005, userInfo: ["msg": "解密后，生成字符串出问题"])
            }
            return originText
        } catch let err {
            throw err
        }
    }
    
    private func getSession(to: String) -> SessionCipher<MavlKeyStore> {
        let addressBob = MavlAddress(identifier: to)
        let session = SessionCipher(store: aliceStore, remoteAddress: addressBob)
        return session
    }
}

//MARK: - Notification Extension
extension NSNotification.Name {
    static let signalLoad = Notification.Name("signalLoad")
}
