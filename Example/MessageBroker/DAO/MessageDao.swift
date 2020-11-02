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
        let sqlMesg = "CREATE TABLE IF NOT EXISTS t_msgs (id INTEGER PRIMARY KEY AUTOINCREMENT, fromUid VARCHAR(32), toUid VARCHAR(32), gid VARCHAR(32), text TEXT, status SMALLINT DEFAULT 0, localId VARCHAR(32) DEFAULT 0, serverId VARCHAR(32) DEFAULT 0, timestamp DATETIME);"
        
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
        if db.executeUpdate(sql, withArgumentsIn: [msg.fromUid, msg.toUid, msg.groupId, msg.status, msg.text, msg.localId ?? "", date]) {
            print("数据插入成功 t_msgs: \(msg.fromUid), \(msg.toUid) : \(msg.text)")
        }else {
            print("数据插入失败 t_msgs: \(msg.fromUid), \(msg.toUid) : \(msg.text)")
        }
    }
    
    /**
     删除会话
     */
    static func deleteChatSession(from: String, gid: String) {
        guard db.open() else { return }

        let sql = "DELETE FROM t_msgs WHERE fromUid = ? AND gid = ?;"
        let res = db.executeUpdate(sql, withArgumentsIn: [from, gid])
        if res {
            print("删除成功")
        }else {
            print("删除失败")
        }
    }
    /**
     查找最近一条信息
     @return Mesg
    */
    static func fetchRecentlyMesg(from: String, to: String) -> Mesg? {
        guard db.open() else { return nil }

        let sql = "SELECT *FROM t_msgs WHERE fromUid = ? AND toUid = ? ORDER BY timestamp DESC LIMIT 1"
        guard let res = db.executeQuery(sql, withArgumentsIn: [from, to]) else { return nil }
        
//        fromUid, toUid, gid, text, status, localId, serverId, timestamp
        while res.next() {
            let gid = res.string(forColumn: "gid")
            let text = res.string(forColumn: "text")
            let status = res.int(forColumn: "status")
            let localId = res.string(forColumn: "localId")
            let serverId = res.string(forColumn: "serverId")
            let timestamp = res.date(forColumn: "timestamp")?.timeIntervalSince1970 ?? 0
            
            var msg = Mesg(fromUid: from, toUid: to, groupId: gid.value, serverId: serverId.value, text: text.value, timestamp: timestamp, status: Int(status))
            msg.localId = localId
            return msg
        }
        
        return nil
    }
    
    /**
     查找所有最近的信息
     */
    static func fetchRecentlyMesgs(from: String) -> [Mesg] {
        guard db.open() else { return [] }

        let sql = "SELECT *FROM t_msgs WHERE fromUid = ? GROUP BY gid ORDER BY timestamp DESC ;"
        guard let res = db.executeQuery(sql, withArgumentsIn: [from]) else { return [] }
        var messages: [Mesg] = []
        while res.next() {
            let gid = res.string(forColumn: "gid")
            let text = res.string(forColumn: "text")
            let status = res.int(forColumn: "status")
            let localId = res.string(forColumn: "localId")
            let serverId = res.string(forColumn: "serverId")
            let timestamp = res.date(forColumn: "timestamp")?.timeIntervalSince1970 ?? 0
            let to = res.string(forColumn: "toUid")
            
            var msg = Mesg(fromUid: from, toUid: to.value, groupId: gid.value, serverId: serverId.value, text: text.value, timestamp: timestamp, status: Int(status))
            msg.localId = localId
            messages.append(msg)
        }
        return messages
    }
    
    /**
     查找所有信息
     @return [Mesg]
    */
    static func fetchAllMesgs(from: String, to: String) -> [Mesg] {
        guard db.open() else { return [] }

        let sql = "SELECT * FROM t_msgs WHERE fromUid = ? AND toUid = ? ORDER BY timestamp ASC;"
        guard let res = try? db.executeQuery(sql, values: [from, to]) else { return [] }
        
        var messages: [Mesg] = []
        while res.next() {
            let gid = res.string(forColumn: "gid")
            let text = res.string(forColumn: "text")
            let status = res.int(forColumn: "status")
            let localId = res.string(forColumn: "localId")
            let serverId = res.string(forColumn: "serverId")
            let timestamp = res.date(forColumn: "timestamp")?.timeIntervalSince1970 ?? 0
            
            var msg = Mesg(fromUid: from, toUid: to, groupId: gid.value, serverId: serverId.value, text: text.value, timestamp: timestamp, status: Int(status))
            msg.localId = localId
            messages.append(msg)
        }

        return messages
    }
}
