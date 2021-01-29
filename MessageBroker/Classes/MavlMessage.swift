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

    func readMessage(msgFrom: String, msgTo: String, msgServerId: String)
    func sendTransparentMessage(msgTo: String, action: String, ext: [String: Any]) -> Error?
}

/**
    Config相关功能的协议
 */
public protocol MavlMessageClientConfig {
    func uploadToken(deliverMesgOnPush isOn: Bool)
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
    func mavl(didReceived messages: [Mesg], isLoadMore: Bool)
    func mavl(didReceivedTransparentMessageWithAction action: String, fromId from: String, ext extension: [String: Any])
    func mavl(mesgReceiptDidChanged receipt: MesgReceipt)
}

public extension MavlMessageStatusDelegate {
    func mavl(willSend: Mesg) {}
    func mavl(willResend: Mesg) {}
    func mavl(didReceived messages: [Mesg], isLoadMore: Bool) {}
    func mavl(didReceivedTransparentMessageWithAction action: String, fromId from: String, ext extension: [String: Any]) {}

    func mavl(mesgReceiptDidChanged receipt: MesgReceipt) {}
}

/**
 MessageBroker主类
 */
public class MavlMessage {
    public typealias SignalCreateCompletion = (Bool) -> Void

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
    
    private var env: String {
        guard let config = config else {
            return ""
        }
        return config.env.description
    }
    
    private var platform: String {
        guard let config = config else {
            return ""
        }
        return config.platform.description
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
    
    private var signalCompletionDict: [String: SignalCreateCompletion] = [:]
    
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
        mqtt.autoReconnect = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(connectTimeoutAction(_:)), name: .connectTimeout, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(signalLoadAction(_:)), name: .signalLoad, object: nil)
    }
    
    @objc func connectTimeoutAction(_ noti: Notification) {
        if let mqtt = mqtt, !mqtt.autoReconnect {
            // 如果没有自动重连逻辑的话，需要将发送队列清空
            // 清空发送队列
            _sendingMessages.removeAll()
            if qos.rawValue > 0 {
                // TODO: 清空mqtt的inflight队列(如果qos > 0)，否则inflight不会释放
            }
        }
        
        guard let obj = noti.object as? [String: ConnectError], let err = obj["err"] else {
            let otherErr = ConnectError.other("StatusQueue connect timeout")
            _logout(withError: otherErr)
            return
        }
        if err == .replaced {
            // 如果是被踢下线的话，主动断开连接，防止进入被踢下线的死循环
            mqtt?.disconnect()
        }
        _logout(withError: err)
    }
    
    // signal通道建立结果（发送方）
    @objc func signalLoadAction(_ noti: Notification) {
        guard let dict = noti.object as? [String: Any],
            let to = dict["to"] as? String, let ret = dict["ret"] as? Bool else { return }
        guard let completion = signalCompletionDict.removeValue(forKey: to) else { return }
        completion(ret)
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
            
        let dispatchTime = DispatchTime.now()
        DispatchQueue.main.asyncAfter(deadline: dispatchTime) {
            mqtt.disconnect()
        }
    }
    
    public func createAGroup(withUsers users: Set<String>) {
        guard let passport = passport else { return }
        // set中不包含自己的话，需要加进去
        var friendList = users
        friendList.insert(passport.uid)
        
        _send(operation: .createGroup(friendList))
    }
    
    public func joinGroup(withGroupId gid: String) {
        _send(operation: .joinGroup(gid))
    }
 
    public func quitGroup(withGroupId gid: String) {
        _send(operation: .quitGroup(gid))
    }
    
    public func addFriend(withUserName: String) {
        // TODO: 目前没有好友管理，只要输入userID就可以加为好友
        delegateGroup?.addFriendSuccess(friendName: withUserName)
    }
    
    // 发送多媒体消息给个人
    public func send(mediaMessage msg: MultiMedia, toFriend fid: String, localId: String) {
        let op = Operation.oneToOne(localId, fid, msg.content)
        _send(operation: op)
    }
    
    // 发送多媒体消息给群组/vmuc
    public func send(mediaMessage msg: MultiMedia, toGroup gid: String, localId: String, withFriends fids: Set<String>) {
        guard let passport = passport else { return }
        var op: Operation
        
        if fids.count > 0 {
            // vmuc
            var allMembers = fids
            allMembers.insert(passport.uid)
            op = .vitualGroup(localId, gid, allMembers, msg.content)
        }else {
            // group
            op = .oneToMany(localId, gid, msg.content)
        }
        _send(operation: op)
    }
    
    // 发送文本消息给个人
    public func send(message msg: String, toFriend fid: String, localId: String) {
        let textMedia = NormalMedia(type: .text, mesg: msg)
        
        send(mediaMessage: textMedia, toFriend: fid, localId: localId)
    }
    
    // 发送文本消息给群组/vmuc
    public func send(message msg: String, toGroup gid: String, localId: String, withFriends fids: Set<String> = []) {
        let textMedia = NormalMedia(type: .text, mesg: msg)
        send(mediaMessage: textMedia, toGroup: gid, localId: localId, withFriends: fids)
    }
    
    public func readMessage(msgFrom: String, msgTo: String, msgServerId: String) {
        let op = Operation.msgReceipt(msgFrom, msgTo, msgServerId, .read)
        _send(operation: op)
    }
    
    public func sendTransparentMessage(msgTo: String, action: String, ext: [String : Any] = [:]) -> Error? {
        guard JSONSerialization.isValidJSONObject(ext) else {
            TRACE("ext 不是json格式")
            return SendError.transparentMesgInvalidExtension.asError()
        }
        let op = Operation.msgTransparent(msgTo, action, ext)
        _send(operation: op)
        return nil
    }         
    
    // MARK: -
    func receivedMessage(msgFrom: String, msgTo: String, msgServerId: String) {
        let op = Operation.msgReceipt(msgFrom, msgTo, msgServerId, .received)
        _send(operation: op)
    }
    
    public func fetchMessages(msgId: String, from: String, type: FetchMessagesType, offset: Int = 20) {
        let op = Operation.fetchMsgs(from, type, msgId, offset)
        _send(operation: op)
    }
    
    private func _send(operation: Operation) {
        let mqttMsg = CocoaMQTTMessage(topic: operation.topic, string: operation.payload, qos: qos)
        mqtt?.publish(mqttMsg)
    }

    private func _logout(withError err: ConnectError) {
        delegateLogin?.logout(withError: err.asError())
    }
    
    private func _logoutWithoutError() {
        delegateLogin?.logout(withError: nil)
    }
}

extension MavlMessage: MavlMessageClientConfig {
    public func uploadToken(deliverMesgOnPush isOn: Bool = true) {
        guard let deviceToken = getDeviceToken() else {
            TRACE("上传token失败，无法获取token")
            return
        }
        _send(operation: .uploadToken(deviceToken, env, platform, isOn))
    }
}

//MARK:- Signal
extension MavlMessage {
    func uploadPublicKey() {
        do {
            let bundle = try SignalUtils.default.generatePublicBundle()
            _send(operation: .uploadPublicKey(bundle))
        } catch let e {
            print(e)
        }
    }
    
    /**
        建立一个Signal加密通道
        1、首先需要去下载对方的公钥bundle
     */
    public func createSingalCipherChannel(toUid: String, completion:@escaping SignalCreateCompletion) {
        // 如果本地存在，那么不需要调用MQTT
        if SignalUtils.default.isExistSession(to: toUid) {
            completion(true)
        }else {
            _send(operation: .fetchPublicKeyBundle(toUid))
            signalCompletionDict[toUid] = completion
        }
    }
    
    /**
        2、获取到bundle以后，解析，传给SignalUtils处理
     */
    private func processBundle(bundleStr: String, to: String) {
        // 建立session
        SignalUtils.default.createSignalSession(bundleStr: bundleStr, to: to)
    }
    
    /**
        发送Signal加密消息
     */
    public func sendSignal(message msg: String, toFriend fid: String, localId: String) {
        let textMedia = NormalMedia(type: .text, mesg: msg)
        sendSignal(mediaMessage: textMedia, toFriend: fid, localId: localId)
    }
    
    /**
        发送Signal加密多媒体消息
     */
    public func sendSignal(mediaMessage msg: MultiMedia, toFriend fid: String, localId: String) {
        let op = Operation.signalMessage(localId, fid, msg.content)
        _send(operation: op)
    }
}

//MARK:- MQTT
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
        if let err = err, let nserr = err as NSError? {
            TRACE("\(nserr.code)-----\(err.localizedDescription)-----\(err)")
        }
        
        _isLogin = false
        // 先将_isLogin 设置为false，然后再去通知StatusQueue和delegate
        StatusQueue.shared.logout()
        
        if let err = err {
            _logout(withError: ConnectError.other(err.localizedDescription))
        }else {
            _logoutWithoutError()
        }
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        TRACE("ack: \(ack)")
        
        if ack == .accept {
            delegateLogin?.loginSuccess()

            _isLogin = true
            // 成功建立连接，上传token
            uploadToken()
            uploadPublicKey()
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
            StatusQueue.shared.updateUserStatus(imAccount: topicModel.friendId, status: message.string.value)
        }else if let topicModel = MesgReceiptTopicModel(topic, mesgText: message.string.value) {
            // 收到消息回执
            guard let state = ReceiptState(rawValue: topicModel.text) else { return }
            
            let recepit = MesgRemoteReceipt(state: state, from: topicModel.toPersonalUid, msgServerId: topicModel.serverId)
            delegateMsg?.mavl(mesgReceiptDidChanged: recepit)
        }else if let topicModel = SignalKeyBundleTopicModel(topic, message.string.value) {
            // 创建Signal加密通道
            processBundle(bundleStr: topicModel.text, to: topicModel.to)
        } else if let topicModel = ReceivedTopicModel(topic, message.string.value) {
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
                delegateMsg?.mavl(didReceived: msgs, isLoadMore: true)
            
            }else if topicModel.operation == 501 {
                guard let data = topicModel.text.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers),
                      let dict = json as? [String: Any] else {
                    return
                }
                
                guard let action = dict["action"] as? String,
                      let ext = dict["ext"] as? [String: Any] else {
                    return
                }
                delegateMsg?.mavl(didReceivedTransparentMessageWithAction: action, fromId: topicModel.from, ext: ext)
            
            }else if topicModel.isMesg {
                let msg = Mesg(topicModel: topicModel)
                
                if _sendingMessages.keys.contains(topicModel.localId) {
                    // 是自己发出去的消息，不需要做received的回执，服务器离线消息仅针对别人发给你的消息
                    // 表明发送成功，从发送队列中移除
                    _sendingMessages.removeValue(forKey: topicModel.localId)
                    // 反馈给业务层消息状态
                    delegateMsg?.mavl(mesgReceiptDidChanged: MesgServerReceipt(state: .sent, from: msg.toUid, msgLocalId: msg.localId.value))
                }else {
                    // 1、收到别人的消息，需要上报已接收的状态
                    receivedMessage(msgFrom: msg.fromUid, msgTo: msg.toUid, msgServerId: msg.serverId)
                }
                
                // 执行完1步骤后，再回调代理（先上报收到消息了，然后再处理信息逻辑）
                delegateMsg?.mavl(didReceived: [msg], isLoadMore: false)
            }else {
                TRACE("收到无效信息:\(topic), \(message.string.value)")
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
