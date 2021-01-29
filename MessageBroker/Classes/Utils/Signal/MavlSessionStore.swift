//
//  MavlSessionStore.swift
//  CCurve25519
//
//  Created by 龙格 on 2021/1/27.
//

import Foundation
import  SignalProtocol

class MavlSessionStore: SessionStore {
    typealias Address = MavlAddress
    
    private var sessions = [Address : Data]()

    func loadSession(for address: Address) -> Data? {
        return sessions[address]
    }
    
    func store(session: Data, for address: Address) throws {
        sessions[address] = session
    }
    
    func containsSession(for address: Address) -> Bool {
        return sessions[address] != nil
    }
    
    func deleteSession(for address: Address) throws {
        sessions[address] = nil
    }
}
