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
    
    //test for amessageTest
//    static let xnAppId = "59"
//    static let xnAppKey = "368913ccfa35c450"
//    static let xnMsgKey = "Emoji_JingNCK567"
}

extension Notification.Name {
    static let loginSuccess = Notification.Name("loginSuccess")
    static let logoutSuccess = Notification.Name("logoutSuccess")
    static let selectedContactsForGroups = Notification.Name("selectedContactsForGroups")
    static let selectedContactsForCircles = Notification.Name("selectedContactsForCircles")
    static let didReceiveMesg = Notification.Name(rawValue: "didReceiveMesg")
    static let willSendMesg = Notification.Name("willSendMesg")
    static let didSendMesg = Notification.Name("didSendMesg")
    static let didSendMesgFailed = Notification.Name("didSendMesgFailed")
    static let quitGroupSuccess = Notification.Name("quitGroupSuccess")
    static let userStatusDidChanged = Notification.Name("userStatusDidChanged")
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
