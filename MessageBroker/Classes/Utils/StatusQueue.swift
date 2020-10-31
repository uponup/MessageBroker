//
//  StatusQueue.swift
//  CocoaAsyncSocket
//
//  Created by 龙格 on 2020/10/31.
//

import Foundation

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
    private var maxInterval: TimeInterval = 180
    private var timer: Timer?
    
    init() {
        timer = Timer(timeInterval: 30, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        timer?.fireDate = Date.distantFuture
    }
    
    func updateUserStatus(imAccount account: String, status type: String = "online") {
        guard let statusEnum = Status(rawValue: type.lowercased()) else { return }
        
        // 数组发生变化的时候，需要通知给业务层
        if statusEnum == .offline {
            guard queue.keys.contains(account) else { return }
            queue.removeValue(forKey: account)
            // todo：如果此用户的在线状态在当前队列中，是否需要发通知（1）给业务层
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
    
    // MARK: - Action
    // 检查是否有连接超时的用户,有的话反馈给用户
    @objc func timerAction() {
        let offlineUsers = queue.filter { !isOnlineStatus(withImAccount: $0.value.imAccount) }.map { $0.value.imAccount }
        
        if offlineUsers.count > 0 {
            delegate?.statusQueue(didOfflineUsers: offlineUsers)
            print("检测到这些用户离线: \(offlineUsers)")
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
    
    deinit {
        self.timer?.invalidate()
        self.timer = nil
    }
}
