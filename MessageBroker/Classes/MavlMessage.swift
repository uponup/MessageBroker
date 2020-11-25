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
    
    func createAGroup(withUsers users: Set<String>)
    func joinGroup(withGroupId gid: String)
    func quitGroup(withGroupId gid: String)
    
    func addFriend(withUserName: String)
    func send(mediaMessage msg: MultiMedia, toFriend fid: String, localId: String)
    func send(mediaMessage msg: MultiMedia, toGroup gid: String, localId: String, withFriends fids: Set<String>)
    
    func send(message msg: String, toFriend fid: String, localId: String)
    func send(message msg: String, toGroup gid: String, localId: String, withFriends fids: Set<String>)
    func fetchMessages(msgId: String, from: String, type: FetchMessagesType, offset: Int)
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
    func mavl(willResend: Mesg)
    func mavl(didRevceived messages: [Mesg], isLoadMore: Bool)
}

public extension MavlMessageStatusDelegate {
    func mavl(willSend: Mesg) {}
    func mavl(willResend: Mesg) {}
    func mavl(didRevceived messages: [Mesg], isLoadMore: Bool) {}
}




/**
 MessageBroker主类
 */
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
        return config.appId
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
    private var _sendingMessages: [String: TopicModelProtocol] = [:]
    private let qos: CocoaMQTTQOS = .qos0
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
        
        let clientId = "\(config.appId)_\(passport.uid)"
        let mqttUserName = "\(config.appId)_\(passport.uid)"
        let mqttPassword = "\(passport.pwd)_\(config.appKey)"
    
        mqtt = CocoaMQTT(clientID: clientId, host: config.host, port: config.port)
        guard let mqtt = mqtt else { return }
        mqtt.username = mqttUserName
        mqtt.password = mqttPassword
        mqtt.keepAlive = 60
        mqtt.delegate = self
        mqtt.enableSSL = true
        mqtt.allowUntrustCACertificate = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(connectTimeoutAction), name: .connectTimeout, object: nil)
    }
    
    @objc func connectTimeoutAction() {
        // 清空发送队列
        _sendingMessages.removeAll()
        if qos.rawValue > 0 {
            // TODO: 清空mqtt的inflight队列(如果qos > 0)，否则inflight不会释放
        }
        
        let err = NSError(domain: "", code: 0, userInfo: ["errmsg": "connect timeout"]) as Error
        delegateLogin?.logout(withError: err)
    }
    
    func checkStatus(withUserName username: String) {
        let topic = "\(appid)/userstatus/\(username)/online"
        mqtt?.subscribe(topic)
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
    
    public func createAGroup(withUsers users: Set<String>) {
        guard let passport = passport else { return }
        // set中不包含自己的话，需要加进去
        var frinedsList = users
        frinedsList.insert(passport.uid)
        
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
    
    public func send(mediaMessage msg: MultiMedia, toFriend fid: String, localId: String) {
        let operation = Operation.oneToOne(localId, fid)
        _send(text: msg.content, operation: operation)
    }
    
    public func send(mediaMessage msg: MultiMedia, toGroup gid: String, localId: String, withFriends fids: Set<String>) {
        guard let passport = passport else { return }
        var operation: Operation

        var allMembers = fids
        
        if fids.count > 0 {
            // vmuc
            allMembers.insert(passport.uid)
            operation = .vitualGroup(localId, gid)
        }else {
            // group
            operation = .oneToMany(localId, gid)
        }
        _send(text: msg.content, operation: operation, fids: allMembers)
    }
    
    public func send(message msg: String, toFriend fid: String, localId: String) {
        let textMedia = NormalMedia(type: .text, mesg: msg)
        
        send(mediaMessage: textMedia, toFriend: fid, localId: localId)
    }
    
    public func send(message msg: String, toGroup gid: String, localId: String, withFriends fids: Set<String> = []) {
        let textMedia = NormalMedia(type: .text, mesg: msg)
        send(mediaMessage: textMedia, toGroup: gid, localId: localId, withFriends: fids)
    }
    
    public func fetchMessages(msgId: String, from: String, type: FetchMessagesType, offset: Int = 20) {
        let operation = Operation.fetchMsgs(from, type, msgId, offset)
        _send(text: "", operation: operation)
    }
    
    private func _send(text: String, operation: Operation, fids: Set<String> = []) {
        guard var cipherText = getCipherText(text: text, operation: operation) else {
            // TODO: 消息发送失败
            return
        }
        if fids.count > 0 {
            cipherText = "\(fids.joined(separator: ","))#\(cipherText)"
        }
        let mqttMsg = CocoaMQTTMessage(topic: operation.topic, string: cipherText, qos: qos)
        mqtt?.publish(mqttMsg)
    }
    
    private func getCipherText(text: String, operation: Operation) -> String? {
        // 发送的是文本消息, 需要加密
        guard let cipherText = EncryptUtils.encrypt(text), operation.isNeedCipher else {
            return text
        }
        return cipherText
    }
}

extension MavlMessage: MavlMessageClientConfig {
    public func uploadToken() {
        guard let deviceToken = getDeviceToken() else {
            TRACE("上传token失败，无法获取token")
            return
        }
        
        let topic = "\(appid)/300/0/"
        
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
        _isLogin = false

        // 先将_isLogin 设置为false，然后再去通知StatusQueue和delegate
        StatusQueue.shared.logout()
        delegateLogin?.logout(withError: err)
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        TRACE("ack: \(ack)")
        
        if ack == .accept {
            delegateLogin?.loginSuccess()

            _isLogin = true
            // 成功建立连接，上传token
            uploadToken()
            // 通知StatusQUeue
            StatusQueue.shared.login()
        }
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        TRACE("message pub | topic: \(message.topic), message: \(message.string.value), id: \(id)")
        
        guard let tempTopicModel = SendTopicModel(message.topic, message.string.value) else { return }
        
        guard tempTopicModel.isMesg else { return }
        guard let topicModel = SendTopicModel(message.topic, tempTopicModel.text) else { return }
        
        if _sendingMessages.keys.contains(topicModel.localId) {
            // 说明已经在重试队列中了，告诉业务层，这是重试(qos > 0的时候)
            delegateMsg?.mavl(willResend: Mesg(topicModel: topicModel))
        }else {
            // 发送消息出去的同时，将消息缓存到发送队列中，成功和失败后再移除
            _sendingMessages[topicModel.localId] = topicModel
        }
        // 给业务层的回调，将要发送信息
        delegateMsg?.mavl(willSend: Mesg(topicModel: topicModel))
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        TRACE("id: \(id)")
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        TRACE("message receive: \(message.string.value), id: \(id), topic: \(message.topic)")
        
        let topic = message.topic
        
        if let topicModel = UserStatusTopicModel(topic) {
            // 用户状态交付StatusQueue队列维护
            print("\(topicModel.friendId)-----上线了")
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
                    guard let received = ReceivedTopicModel(topic, element) else {
                        // 这儿是遍历历史信息，如果解密失败的话，暂定将错误忽略，不必传给业务层
                        return nil
                    }
                    return Mesg(topicModel: received)
                }
                delegateMsg?.mavl(didRevceived: msgs, isLoadMore: true)
            }else {
                guard let received = ReceivedTopicModel(topic, message.string.value) else {
                    // TODO: 错误信息
                    return
                }
                let msg = Mesg(topicModel: received)
                delegateMsg?.mavl(didRevceived: [msg], isLoadMore: false)
                
                // 从发送队列中移除
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
