//
//  UserCenter.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/9/23.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import Foundation

struct Passport {
    var uid: String
    var pwd: String
    
    init(_ uid: String, _ pwd: String) {
        self.uid = uid.lowercased()
        self.pwd = pwd
    }
    
    init(dict: [String: String]) {
        self.uid = (dict["uid"] ?? "").lowercased()
        self.pwd = dict["pwd"] ?? ""
    }
    
    func toDic() -> [String: String] {
        return ["uid": uid, "pwd": pwd]
    }
}

class UserCenter {
    static let center = UserCenter()
    
    private let key = "com.tm.messagebroker.passport"
    private var _passport: Passport? {
        didSet {
            storePassport()
        }
    }
    
    var passport: Passport? {
        return _passport
    }
    
    func login(passport: Passport) {
        _passport = passport
    }
    
    func logout() {
        // todo清除用户数据?
        _passport = nil
    }
    
    // 获取会话列表
    func fetchSessionList() -> [ChatSession] {
        guard let passport = passport else { return [] }
        return MessageDao.fetchRecentlyMesgs(from: passport.uid).map { ChatSession(msg: $0) }
    }
    
    // 获取联系人列表
    func fetchContactsList() -> [Contact] {
        guard let passport = passport else { return [] }
        return ContactsDao.fetchAllContacts(owner: passport.uid)
    }
    
    // 获取群组列表
    func fetchGroupsList() -> [Group] {
        guard let passport = passport else { return [] }
        return GroupsDao.fetchAllGroups(owner: passport.uid)
    }
    
    // 获取圈子列表
    func fetchCirclesList() -> [Circle] {
        guard let passport = passport else { return [] }
        return CirclesDao.fetchAllCircles(owner: passport.uid)
    }
    // 推出群组
    func quit(groupId: String) {
        guard let passport = passport else { return }
        GroupsDao.quitGroup(gid: groupId, owner: passport.uid)
    }
    
    // 删除会话
    func deleteChatSession(gid: String) {
        guard let passport = passport else { return }
        MessageDao.deleteChatSession(from: passport.uid, gid: gid)
    }
    
    private func storePassport() {
        if let passport = _passport {
            UserDefaults.standard.set(passport.toDic(), forKey: key)
        }
    }
}

extension UserCenter {
    static func isMe(uid: String) -> Bool {
        guard let passport = UserCenter.center.passport else { return false }
        return passport.uid == uid
    }
}

// TODO: Delete
extension UserDefaults {
    public class func set(_ value: Any?, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
        UserDefaults.standard.synchronize()
    }
    
    public class func object(forKey key: String) -> Any? {
        return UserDefaults.standard.object(forKey: key)
    }
    
    public class func removeObject(forKey key: String) {
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.synchronize()
    }
}
