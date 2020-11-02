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
    
    func save(sessionList list: [ChatSession]) {
        guard let passport = passport else { return }
        let sessionKey = "\(passport.uid)_sessionList"
        UserDefaults.set(list.map{ $0.toDic() }, forKey: sessionKey)
    }
    
    func fetchSessionList() -> [ChatSession]? {
        guard let passport = passport else { return nil }
        let sessionKey = "\(passport.uid)_sessionList"
        guard let items = UserDefaults.object(forKey: sessionKey) as? [[String: Any]] else {
            return nil
        }
        return items.map{ ChatSession(dict: $0) }
    }
    
    
    func save(contactsList contacts: [String]) {
        guard let passport = passport else { return }
        let contactsKey = "\(passport.uid)_contactsList"
        UserDefaults.set(contacts, forKey: contactsKey)
    }
    
    // 返回(name，im_account)
    func fetchContactsList() -> [Contact] {
        guard let passport = passport else { return [] }
        return ContactsDao.fetchAllContacts(owner: passport.uid)
    }
    
    func quit(groupId: String) {
        guard let passport = passport else { return }
//        Contact
    }
    
    func fetchGroupsList() -> [Group] {
        guard let passport = passport else { return [] }
        return GroupsDao.fetchAllGroups(owner: passport.uid)
    }
    
    func fetchCirclesList() -> [Circle] {
        guard let passport = passport else { return [] }
        return CirclesDao.fetchAllCircles(owner: passport.uid)
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
