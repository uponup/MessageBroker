//
//  UserDefaultsExtension.swift
//  MessageBroker
//
//  Created by 龙格 on 2021/1/29.
//

import Foundation

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

extension UserDefaults {
    
    @discardableResult
    class func executeOnce(withKey key: String, execute: () -> Void) -> Bool {
        if UserDefaults.standard.object(forKey: key) == nil {
            UserDefaults.standard.set(key, forKey: key)
            execute()
            return true
        }else {
            return false
        }
    }
    
    class func executePeriodic(withKey key: String, shortestIntervals: TimeInterval, execute: () -> Void) {
        let preTimeInterval = UserDefaults.standard.double(forKey: key)
        let nowTimeInterval = Date().timeIntervalSince1970
        if preTimeInterval + shortestIntervals <= nowTimeInterval {
            UserDefaults.standard.set(nowTimeInterval, forKey: key)
            execute()
        }
    }
    /// 第X次执行某操作
    @objc class func executeTimes(_ times: Int, withKey key: String, execute: () -> Void) {
        let t = UserDefaults.standard.integer(forKey: key) + 1
        if t == times {
            execute()
        }
        UserDefaults.standard.set(t, forKey: key)
    }
    /// 每X次执行某操作
    class func executeEveryTimes(_ times: Int, withKey key: String, execute: () -> Void) {
        let t = UserDefaults.standard.integer(forKey: key) + 1
        if t % times == 0 {
            execute()
        }
        UserDefaults.standard.set(t, forKey: key)
    }
    
    class func willExecuteWhen(_ when: (Int) -> Bool, withKey key: String, execute: () -> Void) {
        let t = UserDefaults.standard.integer(forKey: key) + 1
        if when(t) {
            execute()
        }
        UserDefaults.standard.set(t, forKey: key)
    }
}
