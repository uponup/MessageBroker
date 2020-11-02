//
//  UserDefaultsExtension.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/11/2.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import Foundation

extension UserDefaults {
    public class func executeOnce(withKey key: String, execute: () -> Void) -> Bool {
        if UserDefaults.standard.object(forKey: key) == nil {
            UserDefaults.standard.set(key, forKey: key)
            execute()
            return true
        }else {
            return false
        }
    }
}
