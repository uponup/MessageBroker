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
        let sqlMesg = "CREATE TABLE IF NOT EXISTS t_msgs (id INTEGER PRIMARY KEY AUTOINCREMENT, fromUid VARCHAR(32), toUid VARCHAR(32), gid VARCHAR(32), text TEXT, status SMALLINT DEFAULT 0, localId VARCHAR(32) DEFAULT 0, serverId VARCHAR(32) DEFAULT 0, timestamp DATETIME, isGroup Bool);"
        
        guard db.open() else { return }

        if db.executeStatements(sqlMesg) {
            print("=====t_msgs 创建成功")
        }else {
            print("=====t_msgs 创建失败")
        }
    }
    
    static func addMesg(msg: Mesg) {
        let sql = "INSERT INTO t_msgs (fromUid, toUid, gid, text, status, localId, timestamp, isGroup) VALUES (?, ?, ?, ?, ?, ?, ?, ?)"
        guard db.open() else { return }
        
        let date = Date(timeIntervalSince1970: msg.timestamp)
        if db.executeUpdate(sql, withArgumentsIn: [msg.fromUid, msg.toUid, msg.groupId, msg.text, msg.status, msg.localId ?? "", date, msg.isGroup]) {
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
     查找所有最近的信息
     */
    static func fetchRecentlyMesgs(from: String) -> [Mesg] {
        guard db.open() else { return [] }

        let sql = "SELECT * FROM (SELECT *FROM t_msgs WHERE fromUid = ? or toUid = ? ORDER BY timestamp DESC ) GROUP BY gid;"
        guard let res = db.executeQuery(sql, withArgumentsIn: [from, from]) else { return [] }
        var messages: [Mesg] = []
        while res.next() {
            let gid = res.string(forColumn: "gid")
            let text = res.string(forColumn: "text")
            let status = res.int(forColumn: "status")
            let localId = res.string(forColumn: "localId")
            let serverId = res.string(forColumn: "serverId")
            let timestamp = res.date(forColumn: "timestamp")?.timeIntervalSince1970 ?? 0
            let to = res.string(forColumn: "toUid")
            let isGroup = res.bool(forColumn: "isGroup")

            var msg = Mesg(fromUid: from, toUid: to.value, groupId: gid.value, serverId: serverId.value, text: text.value, timestamp: timestamp, status: Int(status), isGroup: isGroup)
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
            let isGroup = res.bool(forColumn: "isGroup")

            var msg = Mesg(fromUid: from, toUid: to, groupId: gid.value, serverId: serverId.value, text: text.value, timestamp: timestamp, status: Int(status), isGroup: isGroup)
            msg.localId = localId
            messages.append(msg)
        }
        
        guard let res2 = try? db.executeQuery(sql, values: [to, from]) else { return messages }
        while res2.next() {
            let gid = res2.string(forColumn: "gid")
            let text = res2.string(forColumn: "text")
            let status = res2.int(forColumn: "status")
            let localId = res2.string(forColumn: "localId")
            let serverId = res2.string(forColumn: "serverId")
            let timestamp = res2.date(forColumn: "timestamp")?.timeIntervalSince1970 ?? 0
            let isGroup = res2.bool(forColumn: "isGroup")

            var msg = Mesg(fromUid: to, toUid: from, groupId: gid.value, serverId: serverId.value, text: text.value, timestamp: timestamp, status: Int(status), isGroup: isGroup)
            msg.localId = localId
            messages.append(msg)
        }

        return messages
    }
    
    static func fetchAllMesgs(fromGroup gid: String) -> [Mesg] {
        guard db.open() else { return [] }
        
        let sql = "SELECT *FROM t_msgs WHERE toUId = ? ORDER BY timestamp ASC;"
        guard let res = try? db.executeQuery(sql, values: [gid]) else { return [] }
        
        var messages: [Mesg] = []
        while res.next() {
            let from = res.string(forColumn: "fromUid")
            let to = res.string(forColumn: "toUid")
            let gid = res.string(forColumn: "gid")
            let text = res.string(forColumn: "text")
            let status = res.int(forColumn: "status")
            let localId = res.string(forColumn: "localId")
            let serverId = res.string(forColumn: "serverId")
            let timestamp = res.date(forColumn: "timestamp")?.timeIntervalSince1970 ?? 0
            let isGroup = res.bool(forColumn: "isGroup")

            var msg = Mesg(fromUid: from.value, toUid: to.value, groupId: gid.value, serverId: serverId.value, text: text.value, timestamp: timestamp, status: Int(status), isGroup: isGroup)
            msg.localId = localId
            messages.append(msg)
        }

        return messages
        
    }
}
