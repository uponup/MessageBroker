//
//  GroupsDao.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/11/2.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import Foundation

/**
 群组的数据库操作类
 在IM后台会创建时机的群组信息
 */

struct GroupsDao {
    static let db = SQLiteManager.sharedManager().db

    static func createTable() {
        let sqlGroups = "CREATE TABLE IF NOT EXISTS t_groups (id INTEGER PRIMARY KEY AUTOINCREMENT, owner VARCHAR(32), title VARCHAR(32), gid VARCHAR(32) UNIQUE);"

        guard db.open() else { return }
        
        if db.executeStatements(sqlGroups) {
            print("=====t_groups 创建成功")
        }else {
            print("=====t_groups 创建失败")
        }
    }
    static func dropTable() {
        guard db.open() else { return }
        let sql = "DROP TABLE t_groups;"
        if db.executeStatements(sql) {
            print("=====t_groups 删除成功")
        }else {
            print("=====t_groups 删除失败")
        }
    }
}

extension GroupsDao {
    /**
     创建群组
     */
    static func createGroup(gid: String, owner: String) -> Group? {
        let sql = "INSERT INTO t_groups (owner, gid, title) VALUES (?, ?, ?);"
        guard db.open() else { return nil }
        
        let group = Group(name: "新群组-\(gid[gid.count-6..<gid.count])", groupId: gid)
        
        if db.executeUpdate(sql, withArgumentsIn: [owner, group.groupId, group.name]) {
            print("数据插入成功 t_group: \(group.name), \(gid)")
            return group
        }else {
            print("数据插入失败 t_group: \(group.name), \(gid)")
            return nil
        }
    }
    
    /**
     退出群组
     */
    static func quitGroup(gid: String, owner: String) {
        guard db.open() else { return }
        let sql = "DELETE FROM t_groups WHERE gid = ? AND owner = ?;"
        if db.executeUpdate(sql, withArgumentsIn: [gid, owner]) {
            print("删除成功 t_group: \(gid)")
        }else {
            print("删除成功 t_group: \(gid)")
        }
    }
    
    /**
     更新群组title
     */
    static func updateGroupName(title: String, gid: String) {
        let sql = "UPDATE t_groups SET title = ? WHERE gid = ?;"
        guard db.open() else { return }
        if db.executeUpdate(sql, withArgumentsIn: [title, gid]) {
            print("数据更新成功 t_group: \(title), \(gid)")
        }else {
            print("数据更新失败 t_group: \(title), \(gid)")
        }
    }
    
    /**
     查找所有群组
     @return [Group(title, gid)]
     */
    static func fetchAllGroups(owner: String) -> [Group] {
        let sql = "SELECT * FROM t_groups WHERE owner = ?;"
        guard db.open() else { return [] }
        
        guard let res = try? db.executeQuery(sql, values: [owner]) else { return [] }
        
        var contacts: [Group] = []
        while res.next() {
            guard let title = res.string(forColumn: "title"),
                let gid = res.string(forColumn: "gid") else { continue }
            contacts.append(Group(name: title, groupId: gid))
        }
        return contacts
    }
    
    /**
     查找某个群组信息
     */
    static func fetchGroup(gid: String) -> Group? {
        let sql = "SELECT * FROM t_groups WHERE gid = ?;"
        guard db.open() else { return nil }
        
        guard let res = try? db.executeQuery(sql, values: [gid]) else { return nil }
        
        var group: Group? = nil
        while res.next() {
            guard let title = res.string(forColumn: "title"),
                let gid = res.string(forColumn: "gid") else { continue }
            group = Group(name: title, groupId: gid)
        }
        return group
    }
}

