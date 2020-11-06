//
//  Passport.swift
//  CocoaAsyncSocket
//
//  Created by 龙格 on 2020/10/8.
//

import Foundation

// MARK: - IM登录信息
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

// MARK: - 配置信息
enum MBDomainConfig {
    static let awsLB = "msgapi.adpub.co"
    static let awsHost1 = "im1.adpub.co"  //54.205.75.48
    static let awsHost2 = "im2.adpub.co"  //54.83.120.184
    static let awsHost3 = "im3.adpub.co"  //54.144.161.196
    
    static let localHost = "192.168.1.186"
    
    static let port: UInt16 = 443
}

// MARK: - SDK初始化配置
public struct MavlMessageConfiguration {
    var appId: String
    var appKey: String
    var msgKey: String
    var host: String = MBDomainConfig.awsLB
    var port: UInt16 = MBDomainConfig.port
       
    public init(appid id: String, appkey key: String, msgKey mkey: String) {
        appId = id
        appKey = key
        msgKey = mkey
    }
}
