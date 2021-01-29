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
}
