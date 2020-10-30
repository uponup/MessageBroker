//
//  EncryptUtils.swift
//  CocoaAsyncSocket
//
//  Created by 龙格 on 2020/10/26.
//

import Foundation

private let KEY = "Emoji_JingNCK567"

struct EncryptUtils {
    static func encrypt(_ data: String) -> String? {
        let ivKey = generateIvKey(len: data.bytes.count)
        let cipherBytes = data.bytes.enumerated().map { (offset, element) -> UInt8 in
            let chr1 = ivKey[offset].value
            let sum = UInt8((UInt16(chr1) + UInt16(element))%256)
            print("chr1: \(chr1)    chr2: \(element)    sum: \(sum)")
            return sum
        }
        let cipherText = Data(cipherBytes).base64EncodedString()
        return cipherText
    }

    static func decrypt(_ cipherText: String) -> String? {
        guard let decodeData = NSData(base64Encoded: cipherText, options: NSData.Base64DecodingOptions.init(rawValue: 0)) else {
            print("解析失败")
            return nil
        }
        let contentBytes = [UInt8](decodeData)
        
        let ivKey = generateIvKey(len: contentBytes.count)
        let originText = contentBytes.enumerated().map{ (offset, element) -> UInt8 in
            let chr1 = UInt16(element)
            let chr2 = UInt16(ivKey[offset].value)

            if chr1 < chr2 {
                let originChr = chr1 + 256 - chr2
                return UInt8(originChr)
            }else {
                let originChr = chr1 - chr2
                return UInt8(originChr)
            }
        }
        
        return String(bytes: originText, encoding: .utf8)
    }

    private static func generateIvKey(len: Int) -> String {
        let key = KEY.md5()
        let iv = (0..<len).enumerated().map({ (offset, element) -> String in
            let count = offset % key.count
            return key[count]
            }).joined()
        return iv
    }
}

extension String {
    var value: UInt8 {
        var num: UInt8 = 0
        for code in self.unicodeScalars {
            num = UInt8(code.value);
        }
        return num
    }
}


