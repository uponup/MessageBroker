//
//  SignalAddress.swift
//  CCurve25519
//
//  Created by 龙格 on 2021/1/27.
//

import Foundation
/**
    1、数据持久化采用了NSKeyedArchive来处理，要保存的数据中可能含有MavlAddress类型的key，所以MavlAddress需要遵循NSCoding协议。所以选择MavlAddress为class数据结构。
    2、NSCoding协议为NSObject的协议，普通的元类是不能遵守这个协议，所以让MavlAddress继承自NSObject。
    3、此外，NSObject还自动实现了Hashable和Equatable协议，满足了将MavlAddress作为字典中的key的数据类型。
 */

class MavlAddress: NSObject, NSCoding, NSCopying {
    let identifier: String
    
    init(identifier: String) {
        self.identifier = identifier
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(identifier, forKey: "identifier")
    }
    
    required convenience init?(coder: NSCoder) {
        let identifier = (coder.decodeObject(forKey: "identifier") as? String) ?? ""
        self.init(identifier: identifier)
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        return MavlAddress(identifier: self.identifier)
    }
}

//struct MavlAddress {
//    let identifier: String
//}
//
//extension MavlAddress: Equatable {
//    static func ==(lhs: MavlAddress, rhs: MavlAddress) -> Bool {
//        return lhs.identifier == rhs.identifier
//    }
//}
//
//extension MavlAddress: Hashable {}
//
//extension MavlAddress: CustomStringConvertible {
//    var description: String {
//        return "MavlAddress: \(identifier)"
//    }
//}
