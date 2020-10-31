//
//  MessageDao.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/10/31.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import Foundation

//public var fromUid: String
//public var toUid: String
//public var groupId: String
//public var serverId: String
//public var text: String
//public var status: Int
//public var timestamp: TimeInterval
//public var localId: String?

struct MessageDao {
    static let db = SQLiteManager.sharedManager().db

    static func createTable() {
        let sqlMesg = "CREATE TABLE IF NOT EXISTS t_msgs (id INTEGER PRIMARY KEY AUTOINCREMENT, fromUid VARCHAR(32), toUid VARCHAR(32), gid VARCHAR(32), text TEXT, status SMALLINT DEFAULT 0, localId VARCHAR(32) DEFAULT 0, timestamp DATETIME);"
        
        guard db.open() else { return }

        if db.executeStatements(sqlMesg) {
            print("=====t_msgs 创建成功")
        }else {
            print("=====t_msgs 创建失败")
        }
    }
    
    static func addMesg(msg: Mesg) {
        let sql = "INSERT INTO t_msgs (fromUid, toUid, gid, text, status, localId, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?)"
        guard db.open() else { return }
        
        let date = Date(timeIntervalSince1970: msg.timestamp)
        if db.executeUpdate(sql, withArgumentsIn: [msg.fromUid, msg.toUid, msg.groupId, msg.text, msg.localId ?? "", date]) {
            print("数据插入成功 t_msgs: \(msg.fromUid), \(msg.toUid) : \(msg.text)")
        }else {
            print("数据插入失败 t_msgs: \(msg.fromUid), \(msg.toUid) : \(msg.text)")
        }
    }
    
    /**
     查找所有信息
     @return [(name, imAccount)]
    */
    static func fetchRecentlyMesg(from: String, to: String) -> Mesg? {
        return nil
    }
    
    static func fetchAllMesgs(from: String, to: String) -> [Mesg] {
        let sql = "SELECT * FROM t_msgs;"
        guard db.open() else { return [] }
        
        guard let res = try? db.executeQuery(sql, values: []) else { return [] }
        
        var messages: [Mesg] = []
        while res.next() {
            
        }
        return messages
    }
}
