//
//  DataExtension.swift
//  MessageBroker
//
//  Created by 龙格 on 2021/1/29.
//

import Foundation

extension Data {
    func unarchiveDataToDict<T>(keyType type: T.Type) -> [T: Data]? {
        return NSKeyedUnarchiver.unarchiveObject(with: self) as? [T : Data]
    }
    
    public var bytes: Array<UInt8> {
      Array(self)
    }
}

extension Array where Element == UInt8 {
    var base64: String {
        get {
            Data(bytes: self, count: self.count).base64EncodedString()
        }
        set {}
    }
}
