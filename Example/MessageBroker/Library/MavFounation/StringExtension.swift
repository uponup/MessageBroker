//
//  StringExtension.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/11/2.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import Foundation

extension String {
    public subscript (range: CountableRange<Int>) -> String {
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
    
    public subscript (range: CountableClosedRange<Int>) -> String {
        get {
            return self[range.lowerBound..<(range.upperBound + 1)]
        }
        set {
            self[range.lowerBound..<(range.upperBound + 1)] = newValue
        }
    }
    
    public subscript (index: Int) -> String {
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
