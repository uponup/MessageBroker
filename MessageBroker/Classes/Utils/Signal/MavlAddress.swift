//
//  SignalAddress.swift
//  CCurve25519
//
//  Created by 龙格 on 2021/1/27.
//

import Foundation

struct MavlAddress {
    let identifier: String
}

extension MavlAddress: Equatable {
    static func ==(lhs: MavlAddress, rhs: MavlAddress) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

extension MavlAddress: Hashable {}
extension MavlAddress: Codable {}

extension MavlAddress: CustomStringConvertible {
    var description: String {
        return "MavlAddress: \(identifier)"
    }
}

