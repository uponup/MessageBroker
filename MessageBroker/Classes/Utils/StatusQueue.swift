//
//  StatusQueue.swift
//  CocoaAsyncSocket
//
//  Created by 龙格 on 2020/10/31.
//

import Foundation

// MARK: - 协议
protocol OnlineStatus {
    func checkStatus(_ username: String)
}

// MARK: - 代理接口
public protocol StatusQueueDelegate: class {
    func statusQueue(didOfflineUsers: [String])
    func statusQueue(didOnline user: String)
}

// MARK: - StatusQueue
public class StatusQueue {
    public static var shared = StatusQueue()
    public weak var delegate: StatusQueueDelegate?
    
    private var queue: [String: UserStatus] = [:]
    private var maxInterval: TimeInterval = 80
    private var timer: Timer?
    
    init() {
        timer = Timer(timeInterval: 1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        guard let t = timer else {  return }

        t.fireDate = Date.distantFuture
        RunLoop.current.add(t, forMode: .default)
    }
    
    func updateUserStatus(imAccount account: String, status type: String = "online") {
        guard let statusEnum = Status(rawValue: type.lowercased()) else { return }
        guard MavlMessage.shared.isLogin else {
            connectTimeout()
            return
        }
        
        // 数组发生变化的时候，需要通知给业务层
        if statusEnum == .offline {
            guard queue.keys.contains(account) else { return }
            queue.removeValue(forKey: account)
            delegate?.statusQueue(didOfflineUsers: [account])
        }else {
            let newUserStatus = UserStatus(imAccount: account, status: statusEnum)
            
            if queue.keys.contains(account) {
                // 如果原本就存在该对象，仅更新其时间戳
                queue[account]?.lastUpdate = newUserStatus.lastUpdate
                return
            }
            queue[account] = newUserStatus
            delegate?.statusQueue(didOnline: account)
        }
        
        // 队列中元素个数变化，需要更新定时器触发时机
        timerMonitor()
    }
    
    /**
     查看用户在线状态
     @return Bool 是否在线
     */
    public func isOnline(withImAccount account: String) -> Bool {
        isOnlineStatus(withImAccount: account)
    }
    
    /**
     返回所有在线用户
     @return [String] 在线用户的imAccount
     */
    public func getAllOnlines() -> [String] {
        return queue.filter {
            isOnlineStatus(withImAccount: $0.value.imAccount)
        }.map { $0.key }
    }
    
    func logout() {
        connectTimeout()
    }
    
    func login() {
        guard let passport = MavlMessage.shared.passport else { return }
        updateUserStatus(imAccount: passport.uid)
    }
    
    // MARK: - Action
    // 检查自己是否连接超时
    @objc func timerAction() {

        guard let passport = MavlMessage.shared.passport else {
            connectTimeout()
            return
        }
        guard isOnlineStatus(withImAccount:passport.uid) else {
            connectTimeout()
            return
        }
        
        let offlineUsers = queue.keys.filter{
            !isOnlineStatus(withImAccount: $0)
        }
        
        guard offlineUsers.count > 0 else { return }
        delegate?.statusQueue(didOfflineUsers: offlineUsers)
        // 下线后移除队列中的元素
        queue = queue.filter {
            !offlineUsers.contains($0.key)
        }
    }
    
    // MARK: - Private
    /**
     判断用户是否在线
     return Bool true代表在线
     */
    private func isOnlineStatus(withImAccount account: String) -> Bool {
        guard let userStatus = queue[account] else {  return false }
        
        if Date().timeIntervalSince1970 - userStatus.lastUpdate < maxInterval  {
            return userStatus.status == .online
        }else {
            return false
        }
    }
    
    /**
     定时器触发时机，queue中没有元素的时候暂停定时器，有元素的时候开启定时器
     */
    private func timerMonitor() {
        guard let timer = timer else { return }
        
        timer.fireDate = queue.count == 0 ? Date.distantFuture : Date.distantPast
    }
    
    private func connectTimeout() {
        
        let offlineUsers = queue.map { $0.value.imAccount }
        delegate?.statusQueue(didOfflineUsers: offlineUsers)
        
        timer?.fireDate = Date.distantFuture
        queue.removeAll()
            
        // 在线的话，发一个通知给SDK MavlMessage
        guard MavlMessage.shared.isLogin else { return }

        // 离线后发一个全局通知
        NotificationCenter.default.post(name: .connectTimeout, object: nil)
    }
    
    deinit {
        self.timer?.invalidate()
        self.timer = nil
    }
}

extension StatusQueue: OnlineStatus {
    public func checkStatus(_ username: String) {
        MavlMessage.shared.checkStatus(withUserName: username)
    }
}

// MARK: - 模型
private enum Status: String {
    case online = "online"
    case offline = "offline"
}

private struct UserStatus {
    var imAccount: String
    var status: Status = .offline
    var lastUpdate: TimeInterval = Date().timeIntervalSince1970
}

// MARK: - Notification Extension
extension NSNotification.Name {
    static let connectTimeout = Notification.Name("ConnectTimeout")
}
