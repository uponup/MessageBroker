//
//  ConnectErr.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/12/8.
//

import Foundation

enum SendError {
    case transparentMesgInvalidExtension
    case decryptFailed
    
    var errCode: Int {
        switch self {
        case .transparentMesgInvalidExtension:
            return -2001
        case .decryptFailed:
            return -2002
        }
    }
    
    var errMsg: String {
        switch self {
        case .transparentMesgInvalidExtension:
            return "The extended extension for sending the transparent message is not a valid json format"
        case .decryptFailed:
            return "Failed to decrypt End-To-End message"
        }
    }
    
    func asError() -> Error {
        let err = NSError(domain: "com.mavl.messagebroker", code: errCode, userInfo: ["errorMsg": errMsg]) as Error
        return err
    }
}

enum ConnectError {
    case disconnect
    case timeout
    case replaced
    case other(_ msg: String)   // cocoamqtt disconnect error
    
    var errCode: Int {
        switch self {
        case .disconnect:
            return -1000
        case .timeout:
            return -1001
        case .replaced:
            return -1002
        case .other:
            return -1003
        }
    }
    
    var errMsg: String {
        switch self {
        case .disconnect:
            return "client disconnect to server"
        case .timeout:
            return "client connect timeout"
        case .replaced:
            return "user will be signed in another device"
        case .other(let msg):
            return msg
        }
    }
    
    func asError() -> Error {
        let err = NSError(domain: "", code: errCode, userInfo: ["errorMsg": errMsg]) as Error
        return err
    }
}

extension ConnectError: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        if lhs.errCode == rhs.errCode {
            return true
        }else {
            return false
        }
    }
}
