//
//  MavlSignalError.swift
//  MessageBroker
//
//  Created by 龙格 on 2021/2/3.
//

import Foundation

public enum MavlSignalErrorType: Int, CustomStringConvertible {
    case other = -2000
    case initialFailed = -2001
    case prekeysExists = -2002
    case invalidUtf8 = -2003
    case unknownedIdentityKey = -2004
    case invalidBase64 = -2005
    case untrustIdentityKey = -2006
    case invalidMessage = -2007
    
    public var description: String {
        switch self {
        case .other:
            return "Unknown Error"
        case .initialFailed:
            return "Initial PrekeyBundel Failed"
        case .prekeysExists:
            return "Prekeys Count Enough"
        case .unknownedIdentityKey:
            return "Encrypt Failed, Unknowned IdentityKey"
        case .invalidUtf8:
            return "Invalid Charsets For UTF8"
        case .invalidBase64:
            return "Invalid Charsets For Base64 Decode"
        case .untrustIdentityKey:
            return "Remote IK Not Equal Local IK"
        case .invalidMessage:
            return "VerifyMac Is Failed"
        }
    }
}

class MavlSignalError: Error {
    
    var type: MavlSignalErrorType
    
    init(type: MavlSignalErrorType) {
        self.type = type
    }
}
