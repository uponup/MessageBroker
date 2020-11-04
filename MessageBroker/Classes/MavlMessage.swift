//
//  MavMessage.swift
//  Example
//
//  Created by 龙格 on 2020/9/9.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import Foundation
import CocoaMQTT

/**
    Message相关功能的协议
    TODO: 将方法归类成required和optional
 */
public protocol MavlMessageClient {
    func login(userName name: String, password pwd: String)
    func logout()
    
    func createAGroup(withUsers users: [String])
    func joinGroup(withGroupId gid: String)
    func quitGroup(withGroupId gid: String)
    
    func addFriend(withUserName: String)
    func send(message msg: String, toFriend fid: String)
    func send(message msg: String, toGroup gid: String, withFriends fids: [String])
    
    func fetchMessages(msgId: String, from: String, type: FetchMessagesType, offset: Int)
}

/**
    Status相关功能的协议
 */
public protocol MavlMessageClientStatus {
    func checkStatus(withUserName username: String)
}

/**
    Config相关功能的协议
 */
public protocol MavlMessageClientConfig {
    func uploadToken()
}


/**
    SDK登录状态的回调
 */
public protocol MavlMessageDelegate: class {
    func beginLogin()
    func loginSuccess()
    func logout(withError: Error?)
}

/**
    SDK用户关系的回调
    1、群组管理，2、好友管理
 */
public protocol MavlMessageGroupDelegate: class {
    func createGroupSuccess(groupId gid: String, isLauncher: Bool)
    func joinedGroup(groupId gid: String, someone: String)
    func quitGroup(gid: String, error: Error?)
    
    func addFriendSuccess(friendName name: String)
}

/**
    SDK消息状态的回调
    将要发送、发送成功、收到信息
 */
public protocol MavlMessageStatusDelegate: class {
    func mavl(willSend: Mesg)
    func mavl(didSend: Mesg, error: Error?)
    func mavl(didRevceived messages: [Mesg], isLoadMore: Bool)
}

extension MavlMessageStatusDelegate {
    func mavl(willSend: Mesg) {}
    func mavl(didSend: Mesg, error: Error?) {}
    func mavl(didRevceived messages: [Mesg], isLoadMore: Bool) {}
}

public class MavlMessage {
    public static let shared = MavlMessage()
    public var passport: Passport? {
        return _passport
    }
    
    public var isLogin: Bool {
        guard let value = _isLogin else {
            return false
        }
        return value
    }
    
    var appid: String {
        guard let config = config else { return "" }
        return config.appid
    }
    
    var msgKey: String {
        guard let config = config else { return "" }
        return config.msgKey
    }
    
    
    public weak var delegateLogin: MavlMessageDelegate?
    public weak var delegateMsg: MavlMessageStatusDelegate?
    public weak var delegateGroup: MavlMessageGroupDelegate?
    
    private var config: MavlMessageConfiguration?
    private var _passport: Passport?
    private var _isLogin: Bool?
    private var mqtt: CocoaMQTT?
    
    private var _localMsgId: UInt16 = 0
    private var _sendingMessages: [String: MavlTimer] = [:]
    
    public func initializeSDK(config: MavlMessageConfiguration) {
        self.config = config
    }
    
    private func mqttSetting() {
        guard let config = config else {
            TRACE("请先初始化SDK，然后再登录")
            return
        }
        
        guard let passport = passport else {
            TRACE("请输入帐号密码")
            return
        }
        
        let clientId = "\(config.appid)_\(passport.uid)"
        let mqttUserName = "\(config.appid)_\(passport.uid)"
        let mqttPassword = "\(passport.pwd)_\(config.appkey)"
    
        mqtt = CocoaMQTT(clientID: clientId, host: config.host, port: config.port)
        guard let mqtt = mqtt else { return }
        mqtt.username = mqttUserName
        mqtt.password = mqttPassword
        mqtt.keepAlive = 6000
        mqtt.delegate = self
        mqtt.enableSSL = true
        mqtt.allowUntrustCACertificate = true
    }
    
    
    fileprivate func nextMessageLocalID() -> UInt16 {
        if _localMsgId == UInt16.max {
            _localMsgId = 0
        }
        _localMsgId += 1
        return _localMsgId
    }
}

extension MavlMessage: MavlMessageClient {
    
    public func login(userName name: String, password pwd: String) {
        let passport = Passport(name, pwd)
        _passport = passport
        
        mqttSetting()
        
        guard let mqtt = mqtt else { return }
        
        delegateLogin?.beginLogin()
        _ = mqtt.connect()
    }
    
    public func logout() {
        guard let mqtt = mqtt else { return }
            
        mqtt.disconnect()
    }
    
    public func createAGroup(withUsers users: [String]) {
        let payload = users.map{ "\($0.lowercased())" }.joined(separator: ",")
        let operation = Operation.createGroup
        _send(text: payload, operation: operation)
    }
    
    public func joinGroup(withGroupId gid: String) {
        let operation = Operation.joinGroup(gid)
        _send(text: "", operation: operation)
    }
 
    public func quitGroup(withGroupId gid: String) {
        let operation = Operation.quitGroup(gid)
        _send(text: "", operation: operation)
    }
    
    public func addFriend(withUserName: String) {
        // TODO: 目前没有好友管理，只要输入userID就可以加为好友
        delegateGroup?.addFriendSuccess(friendName: withUserName)
    }
    
    public func send(message msg: String, toFriend fid: String) {
        let localId = nextMessageLocalID()
        let operation = Operation.oneToOne(localId, fid)
        _send(text: msg, operation: operation)
    }
    
    public func send(message msg: String, toGroup gid: String, withFriends fids: [String] = []) {
        var operation: Operation

        if fids.count > 0 {
            // vmuc
            let localId = nextMessageLocalID()
            operation = .vitualGroup(localId, gid)
        }else {
            // group
            let localId = nextMessageLocalID()
            operation = .oneToMany(localId, gid)
        }
        _send(text: msg, operation: operation)
    }
    
    public func fetchMessages(msgId: String, from: String, type: FetchMessagesType, offset: Int = 20) {
        let operation = Operation.fetchMsgs(from, type, msgId, offset)
        _send(text: "", operation: operation)
    }
    
    private func _send(text: String, operation: Operation) {
        guard let mesg = getMesg(text: text, operation: operation) else {
            // TODO: 消息发送失败
            return
        }
        let mqttMsg = CocoaMQTTMessage(topic: operation.topic, string: mesg.text, qos: .qos0)
        mqtt?.publish(mqttMsg)
        
        
        // TODO: 超时检测
        let sendingTimer = MavlTimer.after(3) { [unowned self] in
            self.delegateMsg?.mavl(didSend: mesg, error: MavlMessageError.sendFailed)
        }
        _sendingMessages[operation.localId] = sendingTimer
    }
    
    private func getMesg(text: String, operation: Operation) -> Mesg? {
        if operation.isNeedCipher {
            // 发送的是文本消息, 需要加密
            guard let cipherText = EncryptUtils.encrypt(text),
                let cipherTopic = SendTopicModel(operation.topic, cipherText) else {
                return nil
            }
            return Mesg(topicModel: cipherTopic)
        }else {
            guard let topicModel = SendTopicModel(operation.topic, text) else { return nil }
            return Mesg(topicModel: topicModel)
        }
    }
}

extension MavlMessage: MavlMessageClientStatus {
    public func checkStatus(withUserName username: String) {
        let topic = "\(appid)/userstatus/\(username)/online"
        
        mqtt?.subscribe(topic)
    }
}

extension MavlMessage: MavlMessageClientConfig {
    public func uploadToken() {
        guard let deviceToken = getDeviceToken() else {
            TRACE("上传token失败，无法获取token")
            return
        }
        
        let msgId = nextMessageLocalID()
        let topic = "\(appid)/300/\(msgId)/"
        
        mqtt?.publish(topic, withString: deviceToken)
    }
}

extension MavlMessage: CocoaMQTTDelegate {
    public func mqtt(_ mqtt: CocoaMQTT, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
       TRACE("trust: \(trust)")
       /// Validate the server certificate
       ///
       /// Some custom validation...
       ///
       /// if validatePassed {
       ///     completionHandler(true)
       /// } else {
       ///     completionHandler(false)
       /// }
       completionHandler(true)
    }
    
    public func mqttDidPing(_ mqtt: CocoaMQTT) {
        TRACE()
    }
    
    public func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        TRACE()
    }
    
    public func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        TRACE("\(err?.localizedDescription ?? "")")
        
        delegateLogin?.logout(withError: err)
        _isLogin = false
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        TRACE("ack: \(ack)")
        
        if ack == .accept {
            delegateLogin?.loginSuccess()

            _isLogin = true
    //        成功建立连接，上传token
            uploadToken()
        }
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        TRACE("message pub: \(message.string.value), id: \(id)")
        
//        TODO: 这儿为什么用SendingTopicModel，而不是用TopicModel
        guard var topicModel = SendTopicModel(message.topic, message.string.value) else { return }
        
        if topicModel.isNeedDecrypt {
            //解密
            guard let originText = EncryptUtils.decrypt(message.string.value) else {
                // TODO: 解密willSend的消息失败, 是否需要报错
                return }
            topicModel.text = originText
            delegateMsg?.mavl(willSend: Mesg(topicModel: topicModel))
        }
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        TRACE("id: \(id)")
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        TRACE("message receive: \(message.string.value), id: \(id), topic: \(message.topic)")
        
        let topic = message.topic
        
        if let topicModel = UserStatusTopicModel(topic) {
            // 用户状态交付StatusQueue队列维护
            StatusQueue.shared.updateUserStatus(imAccount: topicModel.friendId, status: message.string.value)
        }else if let topicModel = ReceivedTopicModel(topic, message.string.value) {
            if topicModel.operation == 0 {
                // create a group
                guard let passport = passport else { return }
                let isLauncher = passport.uid == topicModel.from
                delegateGroup?.createGroupSuccess(groupId: topicModel.to, isLauncher: isLauncher)
            }else if topicModel.operation == 201 {
                delegateGroup?.joinedGroup(groupId: topicModel.to, someone: topicModel.from)
            }else if topicModel.operation == 202 {
                delegateGroup?.quitGroup(gid: topicModel.to, error: nil)
            }else if topicModel.operation == 401 {
                let msgs = message.string.value.components(separatedBy: "##").compactMap { element -> Mesg? in
                    guard let originText = EncryptUtils.decrypt(element) else {
                        // TODO: 解密失败，返回错误信息
                        guard let received = ReceivedTopicModel(topic, element) else {  return nil }
                        return Mesg(topicModel: received)
                    }
                    
                    guard let received = ReceivedTopicModel(topic, originText) else { return nil }
                    return Mesg(topicModel: received)
                }
                delegateMsg?.mavl(didRevceived: msgs, isLoadMore: true)
            }else {
                guard let originText = EncryptUtils.decrypt(message.string.value),
                    let received = ReceivedTopicModel(topic, originText) else {
                    // TODO: 解密失败，返回错误信息
                    return
                }
                let msg = Mesg(topicModel: received)
                delegateMsg?.mavl(didRevceived: [msg], isLoadMore: false)
                
                let sendingTimer = _sendingMessages[topicModel.localId]
                sendingTimer?.suspend()
                _sendingMessages.removeValue(forKey: topicModel.localId)
            }
        }else {
            // TODO: 非法Topic，返回错误状态
            TRACE("收到的信息Topic不符合规范：\(topic)")
        }
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topics: [String]) {
        TRACE("subscribed: \(topics)")
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        TRACE("topic: \(topic)")
    }
}


fileprivate extension MavlMessage {
    func TRACE(_ message: String = "", fun: String = #function) {
        let names = fun.components(separatedBy: ":")
        var prettyName: String
        if names.count > 2 {
            prettyName = names[1]
        } else {
            prettyName = names[0]
        }
        
        if fun == "mqttDidDisconnect(_:withError:)" {
            prettyName = "didDisconnect"
        }

        print("[TRACE] [\(prettyName)]: \(message)")
    }
}

public enum MavlMessageError: Error, CustomStringConvertible {
    case sendFailed
    case encryptFailed
    
    public var description: String {
        switch self {
        case .sendFailed:
            return "send failed"
        case .encryptFailed:
            return "encrypt faield"
        }
    }
}
