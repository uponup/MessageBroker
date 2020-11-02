//
//  DateExtension.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/11/2.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import Foundation

extension Date {
    public func toString(with format: DateFormat) -> String {
        return toString(withFormatString: format.rawValue)
    }
    
    public func toString(withFormatString string: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = string
        formatter.timeZone = TimeZone.current
        return formatter.string(from: self)
    }
}

public enum DateFormat: String {
    case MMddHHmm = "MM-dd HH:mm"
    case yyyyMMddHHmm = "yyyy MM-dd HH:mm"
    case yyyyMMddHHmmss = "yyyy MM-dd HH:mm:ss"
}
