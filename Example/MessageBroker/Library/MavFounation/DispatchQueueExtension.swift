//
//  DispatchQueueExtension.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/11/2.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import Foundation

extension DispatchQueue {
    private static var _onceTracker: [String] = []
    
    public static func once(token: String, block:() -> Void) {
        objc_sync_enter(self)
        if !_onceTracker.contains(token) {
            _onceTracker.append(token)
            block()
        }
        objc_sync_exit(self)
    }
}
