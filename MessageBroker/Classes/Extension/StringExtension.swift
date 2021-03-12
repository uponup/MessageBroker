//
//  StringExtension.swift
//  CocoaAsyncSocket
//
//  Created by 龙格 on 2020/10/30.
//

import Foundation

extension String {
    public var bytes: Array<UInt8> {
        data(using: String.Encoding.utf8, allowLossyConversion: true)?.bytes ?? Array(utf8)
    }
    
    //MARK: - 下标重载
    subscript (range: CountableRange<Int>) -> String {
        get {
            if self.count < range.upperBound { return "" }
            let startIndex = self.index(self.startIndex, offsetBy: range.lowerBound)
            let endIndex = self.index(self.startIndex, offsetBy: range.upperBound)
            return self[startIndex..<endIndex].toString()
        }
        set {
            if self.count < range.upperBound { return }
            let startIndex = self.index(self.startIndex, offsetBy: range.lowerBound)
            let endIndex = self.index(self.startIndex, offsetBy: range.upperBound)
            self.replaceSubrange(startIndex..<endIndex, with: newValue)
        }
    }
    
    subscript (range: CountableClosedRange<Int>) -> String {
        get {
            return self[range.lowerBound..<(range.upperBound + 1)]
        }
        set {
            self[range.lowerBound..<(range.upperBound + 1)] = newValue
        }
    }
    
    subscript (index: Int) -> String {
        get {
            guard index < count else { return "" }
            let str = self[self.index(startIndex, offsetBy: index)]
            return String(str)
        }
        set {
            self[index...index] = newValue
        }
    }
}

// MARK: - URLEncode
extension String {
    func URLDecoding() -> String? {
        return self.removingPercentEncoding
    }
    
    func URLEncoding() -> String? {
        return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
    
    // query to dict
    func queryParameters() -> [String: Double] {
        let queryPairs = self.components(separatedBy: "&").compactMap { pair -> (String, Double)? in
            let components = pair.components(separatedBy: "=")
            guard let key = components.first, let value = components.last else {
                return nil
            }
                        
            return (key, Double(value) ?? 0)
        }

        return Dictionary(uniqueKeysWithValues: queryPairs)
    }
}

extension String {
    func removeWhitespaceAndNewLine() -> String {
        var string = replacingOccurrences(of: " ", with: "")
        string = replacingOccurrences(of: "\r", with: "")
        string = replacingOccurrences(of: "\n", with: "")
        return string
    }
}

extension Substring {
    public func toString() -> String {
        return String(self)
    }
}
