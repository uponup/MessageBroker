//
//  Passport.swift
//  CocoaAsyncSocket
//
//  Created by 龙格 on 2020/10/8.
//

import Foundation

public struct Passport {
    public var uid: String
    public var pwd: String
    
    public init(_ uid: String, _ pwd: String) {
        self.uid = uid.lowercased()
        self.pwd = pwd
    }
    
    public init(dict: [String: String]) {
        self.uid = (dict["uid"] ?? "").lowercased()
        self.pwd = dict["pwd"] ?? ""
    }
    
    public func toDic() -> [String: String] {
        return ["uid": uid, "pwd": pwd]
    }
}
