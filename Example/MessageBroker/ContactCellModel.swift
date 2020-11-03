//
//  ContactCellModel.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/9/26.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import Foundation


enum ContactCellModel {
    case group(Group)
    case circle(Circle)
    case contact(Contact)
    
    var name: String {
        switch self {
        case .group(let g):
            return g.name
        case .circle(let c):
            return c.name
        case .contact(let c):
            return c.name
        }
    }

    var imAccount: String? {
        switch self {
        case .contact(let c):
            return c.imAccount
        default:
            return nil
        }
    }
    
    var groupId: String? {
        switch self {
        case .group(let g):
            return g.groupId
        default:
            return nil
        }
    }
    
    var circleId: String? {
        switch self {
        case .circle(let c):
            return c.vmucId
        default:
            return nil
        }
    }
}

struct Group {
    var name: String
    var groupId: String
}

struct Circle {
    var name: String
    var vmucId: String
    var users: String
    
    var userList: [String] {
        users.split(separator: "_").map{ String($0) }
    }
}

struct Contact {
    var name: String
    var imAccount: String
}
