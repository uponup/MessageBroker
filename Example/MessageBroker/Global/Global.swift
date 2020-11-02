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
}

extension Notification.Name {
    static let loginSuccess = Notification.Name("loginSuccess")
    static let logoutSuccess = Notification.Name("logoutSuccess")
    static let selectedContacts = Notification.Name("selectedContacts")
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
