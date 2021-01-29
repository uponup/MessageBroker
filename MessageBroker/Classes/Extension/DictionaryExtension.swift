//
//  DictionaryExtension.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/12/1.
//

import Foundation

extension Dictionary {
    var toJson: String {
        guard let data = try? JSONSerialization.data(withJSONObject: self, options: JSONSerialization.WritingOptions()) else {
            return ""
        }
        let jsonStr = String(data: data, encoding: .utf8)
        return jsonStr.value
    }
    
    var archivedData: Data {
        NSKeyedArchiver.archivedData(withRootObject: self)
    }
}
