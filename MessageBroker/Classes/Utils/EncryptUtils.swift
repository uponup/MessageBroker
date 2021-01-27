//
//  EncryptUtils.swift
//  CocoaAsyncSocket
//
//  Created by 龙格 on 2020/10/26.
//

import Foundation

//MARK: - 普通加密
struct EncryptUtils {
    static func encrypt(_ data: String) -> String? {
        let ivKey = generateIvKey(len: data.bytes.count)
        print("加密的ivKey:", ivKey)
        let cipherBytes = data.bytes.enumerated().map { (offset, element) -> UInt8 in
            let chr1 = ivKey[offset].value
            let sum = UInt16(chr1)%256 + UInt16(element)
            print("chr1: \(chr1)    chr2: \(element)    sum: \(sum)")
            return UInt8(sum & 255)
        }

        return Data(cipherBytes).base64EncodedString()
    }

    static func decrypt(_ cipherText: String) -> String? {
        let cipher = cipherText.removeWhitespaceAndNewLine()
        guard let decodeData = Data(base64Encoded: cipher) else {
            print("解析失败")
            return nil
        }
        
        let contentBytes = [UInt8](decodeData)
        
        let ivKey = generateIvKey(len: contentBytes.count)
        print("解密的ivKey：\(ivKey)")
        let originBytes = contentBytes.enumerated().map{ (offset, element) -> UInt8 in
            let chr1 = UInt16(element)
            let chr2 = UInt16(ivKey[offset].value)

            if chr1 < chr2 {
                let originChr = chr1 + 256 - chr2
                print("chr1: \(chr1)    chr2: \(chr2)    origin: \(originChr)")
                return UInt8(originChr)
            }else {
                let originChr = chr1 - chr2
                    
                print("chr1: \(chr1)    chr2: \(chr2)    origin: \(originChr)")
                return UInt8(originChr)
            }
        }
        return String(bytes: originBytes, encoding: .utf8)
    }

    private static func generateIvKey(len: Int) -> String {
        let key = MavlMessage.shared.msgKey.md5()
        let iv = (0..<len).enumerated().map({ (offset, _) -> String in
            let count = offset % key.count
            return key[count]
            }).joined()
        return iv
    }
}

//MARK: - 扩展
extension String {
    var value: UInt8 {
        var num: UInt8 = 0
        for code in self.unicodeScalars {
            num = UInt8(code.value);
        }
        return num
    }
}


