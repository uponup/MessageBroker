//
//  OptionalExtension.swift
//  CocoaAsyncSocket
//
//  Created by 龙格 on 2020/11/4.
//

import Foundation

// MARK: String
extension Optional where Wrapped == String {
    public var value: String {
        switch self {
        case .none:
            return ""
        case .some(let v):
            return v;
        }
    }
}
