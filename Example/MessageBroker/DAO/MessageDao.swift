//
//  MessageDao.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/10/31.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import Foundation

//public var local: String
//public var remote: String
//public var groupId: String
//public var serverId: String
//public var text: String
//public var status: Int
//public var timestamp: TimeInterval
//public var localId: String?

struct MessageDao {
    static let db = SQLiteManager.sharedManager().db

    static func createTable() {
        let sqlMesg = "CREATE TABLE IF NOT EXISTS t_msgs (id INTEGER PRIMARY KEY AUTOINCREMENT, local VARCHAR(32), remote VARCHAR(32), conversationId VARCHAR(32), text TEXT, status SMALLINT DEFAULT 0, localId VARCHAR(32) DEFAULT 0, serverId VARCHAR(32) DEFAULT 0, timestamp DATETIME, isOut Bool, conversationType SMALLINT);"
        
        guard db.open() else { return }

        if db.executeStatements(sqlMesg) {
            print("=====t_msgs 创建成功")
        }else {
            print("=====t_msgs 创建失败")
        }
    }
    
    static func dropTable() {
        guard db.open() else { return }
        let sql = "DROP TABLE t_msgs;"
        if db.executeStatements(sql) {
            print("=====t_msgs 删除成功")
        }else {
            print("=====t_msgs 删除失败")
        }
    }
}

extension MessageDao {
    
    static func addMesg(msg: Message) {
        let sql = "INSERT INTO t_msgs (local, remote, conversationId, text, status, localId, serverId, timestamp, isOut, conversationType) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
        guard db.open() else { return }
        
        let date = Date(timeIntervalSince1970: msg.timestamp)
        if db.executeUpdate(sql, withArgumentsIn: [msg.localAccount, msg.remoteAccount, msg.conversationId, msg.text, msg.status, msg.localId, msg.serverId, date, msg.isOutgoing, msg.conversationType.rawValue]) {
            print("数据插入成功 t_msgs: \(msg.remoteAccount) : \(msg.text)")
        }else {
            print("数据插入失败 t_msgs: \(msg.remoteAccount) : \(msg.text)")
        }
    }
    
    /**
     删除会话
     */
    static func deleteChatSession(local: String, conversationId: String) {
        guard db.open() else { return }

        let sql = "DELETE FROM t_msgs WHERE local = ? AND conversationId = ?;"
        let res = db.executeUpdate(sql, withArgumentsIn: [local, conversationId])
        if res {
            print("删除成功")
        }else {
            print("删除失败")
        }
    }
    
    /**
     更新
     */
    static func updateMessage(msg: Message) {
        guard db.open() else { return }
        
        let sql = "UPDATE t_msgs SET status = ?, SET serverId = ?, set timestamp = ? WHERE localId = ?"
        let res = db.executeUpdate(sql, withArgumentsIn: [msg.status, msg.serverId, msg.timestamp, msg.localId])
        if res {
            print("更新成功")
        }else {
            print("更新失败")
        }
    }
    
    /**
     查找所有最近的信息
     */
    static func fetchRecentlyMesgs(from: String) -> [Message] {
        guard db.open() else { return [] }

        let sql = "SELECT * FROM (SELECT *FROM t_msgs WHERE local = ? ORDER BY timestamp DESC ) GROUP BY conversationId;"
        guard let res = db.executeQuery(sql, withArgumentsIn: [from, from]) else { return [] }
        var messages: [Message] = []
        while res.next() {
            let id = res.int(forColumn: "id")
            let text = res.string(forColumn: "text").value
            let localAccount = res.string(forColumn: "local").value
            let remoteAccount = res.string(forColumn: "remote").value
            let conversationId = res.string(forColumn: "conversationId").value
            let localId = res.string(forColumn: "localId").value
            let serverId = res.string(forColumn: "serverId").value
            let status = Int(res.int(forColumn: "status"))
            let timestamp = res.date(forColumn: "timestamp")?.timeIntervalSince1970 ?? 0
            let isOut = res.bool(forColumn: "isOut")
            let conversationType = Int(res.int(forColumn: "conversationType"))
            
            let msg = Message(id: id, text: text, local: localAccount, remote: remoteAccount, conversationId: conversationId, localId: localId, serverId: serverId, status: status, timestamp: timestamp, conversationType: conversationType, isOutgoing: isOut)
            messages.append(msg)
        }
        return messages
    }
    
    /**
     查找所有信息
     @return [Mesg]
    */
    static func fetchAllMesgs(local: String, remote: String) -> [Message] {
        guard db.open() else { return [] }

        let sql = "SELECT * FROM t_msgs WHERE local = ? AND remote = ? ORDER BY timestamp ASC;"
        guard let res = try? db.executeQuery(sql, values: [local, remote]) else { return [] }
        
        var messages: [Message] = []
        while res.next() {
            let id = res.int(forColumn: "id")
            let text = res.string(forColumn: "text").value
            let localAccount = res.string(forColumn: "local").value
            let remoteAccount = res.string(forColumn: "remote").value
            let conversationId = res.string(forColumn: "conversationId").value
            let localId = res.string(forColumn: "localId").value
            let serverId = res.string(forColumn: "serverId").value
            let status = Int(res.int(forColumn: "status"))
            let timestamp = res.date(forColumn: "timestamp")?.timeIntervalSince1970 ?? 0
            let isOut = res.bool(forColumn: "isOut")
            let conversationType = Int(res.int(forColumn: "conversationType"))
            
            let msg = Message(id: id, text: text, local: localAccount, remote: remoteAccount, conversationId: conversationId, localId: localId, serverId: serverId, status: status, timestamp: timestamp, conversationType: conversationType, isOutgoing: isOut)
            messages.append(msg)
        }
        return messages
    }
    
    static func fetchAllMesgs(fromGroup conversationId: String) -> [Message] {
        guard db.open() else { return [] }
        
        let sql = "SELECT *FROM t_msgs WHERE conversationId = ? ORDER BY timestamp ASC;"
        guard let res = try? db.executeQuery(sql, values: [conversationId]) else { return [] }
        
        var messages: [Message] = []
        while res.next() {
            let id = res.int(forColumn: "id")
            let text = res.string(forColumn: "text").value
            let localAccount = res.string(forColumn: "local").value
            let remoteAccount = res.string(forColumn: "remote").value
            let conversationId = res.string(forColumn: "conversationId").value
            let localId = res.string(forColumn: "localId").value
            let serverId = res.string(forColumn: "serverId").value
            let status = Int(res.int(forColumn: "status"))
            let timestamp = res.date(forColumn: "timestamp")?.timeIntervalSince1970 ?? 0
            let isOut = res.bool(forColumn: "isOut")
            let conversationType = Int(res.int(forColumn: "conversationType"))
            
            let msg = Message(id: id, text: text, local: localAccount, remote: remoteAccount, conversationId: conversationId, localId: localId, serverId: serverId, status: status, timestamp: timestamp, conversationType: conversationType, isOutgoing: isOut)
            messages.append(msg)
        }

        return messages
    }
    
    static func fetchLastOne() -> Int32 {
        guard db.open() else { return 0 }
        let sql = "SELECT MAX(localId) as max FROM t_msgs"
        
        guard let res = try? db.executeQuery(sql, values: []) else { return 0}
        while res.next() {
            let id = res.int(forColumn: "max")
            return id
        }
        return 0
    }
}
