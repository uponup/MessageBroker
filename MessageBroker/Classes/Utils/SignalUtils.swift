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
    private let aliceStore = MavlKeyStore()
    
    init() {
        // 公钥仅生成一次
        UserDefaults.executeOnce(withKey: "install_signal") {
            do {
                let data = try SignalCrypto.generateIdentityKeyPair()
                print(Array(data))
            } catch let e {
                print(e)
            }
        }
    }
    
    func createSignalSession(bundleStr: String, to: String) {
        let address = MavlAddress(identifier: to)
        
        guard let data = bundleStr.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers),
              let dict = json as? [String: Any] else {
            return
        }
        
        
    }
    
    func generatePublicBundle() throws -> [String: Any] {
        do {
            let identityKey: Data = try aliceStore.identityKeyStore.getIdentityKeyPublicData()
            let prekeys: [Data] = try aliceStore.createPreKeys(count: 0)
            let signedPrekey: Data = try aliceStore.updateSignedPrekey()
            
            let uploadDict: [String: Any] = [
                "identityKey": identityKey.base64EncodedString(),
                "prekeys": prekeys.map{ $0.base64EncodedString()},
                "signedPrekey": signedPrekey.base64EncodedString()
            ]            
            return uploadDict
        } catch  {
            throw NSError(domain: "com.mavl.signal", code: 0, userInfo: ["msg": "初始化公钥失败"])
        }
    }
    
    // 将Signal加密后密文的protoData采用base64编码后返回
    func encrypt(_ data: String, _ to: String) -> String? {
        let address = MavlAddress(identifier: to)
        guard let _ = try? aliceStore.identityKeyStore.identity(for: address) else {
            downloadPublicKeyBundle()
            return nil
        }
        return nil
    }
    
    // 先用base64解码，获取得到protoData，然后构造CipherTextMessage用来解密
    func decrypt(_ data: String, _ from: String) -> String? {
        return nil
    }
    
    
    private func getSession(to: String) -> SessionCipher<MavlKeyStore> {
        let addressBob = MavlAddress(identifier: to)
        let session = SessionCipher(store: aliceStore, remoteAddress: addressBob)
        return session
    }
}


fileprivate extension UserDefaults {
    class func executeOnce(withKey key: String, execute: () -> Void) -> Bool {
        if UserDefaults.standard.object(forKey: key) == nil {
            UserDefaults.standard.set(key, forKey: key)
            execute()
            return true
        }else {
            return false
        }
    }
}
