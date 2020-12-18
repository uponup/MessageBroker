//
//  Global.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/9/21.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import Foundation
@_exported import MessageBroker

enum GlobalConfig {
    static let xnAppId = "56"
    static let xnAppKey = "c90265a583aaea81"
    static let xnMsgKey = "Emoji_JingNCK567"
    
    // for amessageTest
//    static let xnAppId = "59"
//    static let xnAppKey = "368913ccfa35c450"
//    static let xnMsgKey = "Emoji_JingNCK567"
    
    // for amessage
//    static let xnAppId = "65"
//    static let xnAppKey = "c33d0f3ed100ca3a"
//    static let xnMsgKey = "Emoji_JingNCK567"
    
    // for iFinder
//    static let xnAppId = "68"
//    static let xnAppKey = "d8aeb68682dd3c81"
//    static let xnMsgKey = "bafb369a23955e52"
}

extension Notification.Name {
    static let loginSuccess = Notification.Name("loginSuccess")
    static let logoutSuccess = Notification.Name("logoutSuccess")
    static let selectedContactsForGroups = Notification.Name("selectedContactsForGroups")
    static let selectedContactsForCircles = Notification.Name("selectedContactsForCircles")
    static let didReceiveMesg = Notification.Name(rawValue: "didReceiveMesg")
    static let willSendMesg = Notification.Name("willSendMesg")
    static let quitGroupSuccess = Notification.Name("quitGroupSuccess")
    static let userStatusDidChanged = Notification.Name("userStatusDidChanged")
    static let mesgStateDidChanged = Notification.Name("mesgStateDidChanged")
}

// 业务层自定义透传消息类型
enum TransparentMesg {
    static let inputing = "Inputing"
}

func showHud(_ msg: String) {
    print(msg)
}

func isMe(_ imAccount: String?) -> Bool {
    guard let passport = UserCenter.center.passport, let imAccount = imAccount else {
        return false
    }
    return imAccount == passport.uid
}

func delay(_ timeInterval: TimeInterval, _ block: @escaping () -> Void) {
    let dispatchTime = DispatchTime.now() + Double(Int64(timeInterval * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
    DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: block)
}
