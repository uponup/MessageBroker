//
//  ContactsDao.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/10/31.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import Foundation

struct ContactsDao {
    
    static let db = SQLiteManager.sharedManager().db

    static func createTable() {
        let sqlContacts = "CREATE TABLE IF NOT EXISTS t_contacts (id INTEGER PRIMARY KEY AUTOINCREMENT, owner VARCHAR(32), name VARCHAR(32), im_account VARCHAR(32));"
        let sqlGroups = "CREATE TABLE IF NOT EXISTS t_groups (id INTEGER PRIMARY KEY AUTOINCREMENT, owner VARCHAR(32), title VARCHAR(32), gid VARCHAR(32));"
        
        guard db.open() else { return }

        if db.executeStatements(sqlContacts) {
            print("=====t_contacts 创建成功")
        }else {
            print("=====t_contacts 创建失败")
        }
        
        if db.executeStatements(sqlGroups) {
            print("=====t_groups 创建成功")
        }else {
            print("=====t_contacts 创建失败")
        }
    }
}

// MARK: - 联系人管理
extension ContactsDao {
    static func addContact(owner: String, name: String, imAccount: String) {
        let sql = "INSERT INTO t_contacts (owner, name, im_account) VALUES (?, ?, ?);"
        guard db.open() else { return }

        if db.executeUpdate(sql, withArgumentsIn: [owner, name, imAccount]) {
            print("数据插入成功 t_contact: \(name), \(imAccount)")
        }else {
            print("数据插入失败 t_contact: \(name)")
        }
    }
    
    /**
     查找所有好友
     @return [(name, imAccount)]
    */
    static func fetchAllContacts(owner: String) -> [(String, String)] {
        let sql = "SELECT * FROM t_contacts WHERE owner = ?;"
        guard db.open() else { return [] }
        
        guard let res = try? db.executeQuery(sql, values: [owner]) else { return [] }
        
        var contacts: [(String, String)] = []
        while res.next() {
            guard let name = res.string(forColumn: "name"),
                let imAccount = res.string(forColumn: "im_account") else { continue }
            contacts.append((name, imAccount))
        }
        return contacts
    }
}

// MARK: - 群组管理
extension ContactsDao {
    static func createGroup(gid: String, title: String = "") {
        let sql = "INSERT INTO t_groups (owner, gid, title) VALUES (?, ?, ?);"
        guard db.open() else { return }
        
        if db.executeUpdate(sql, withArgumentsIn: [gid, title]) {
            print("数据插入成功 t_group: \(title), \(gid)")
        }else {
            print("数据插入失败 t_group: \(title), \(gid)")
        }
    }
    
    /**
     查找所有群组
     @return [(title, gid)]
     */
    static func fetchAllGroups(owner: String) -> [(String, String)] {
        let sql = "SELECT * FROM t_groups WHERE owner = ?;"
        guard db.open() else { return [] }
        
        guard let res = try? db.executeQuery(sql, values: [owner]) else { return [] }
        
        var contacts: [(String, String)] = []
        while res.next() {
            guard let title = res.string(forColumn: "title"),
                let gid = res.string(forColumn: "gid") else { continue }
            contacts.append((title, gid))
        }
        return contacts
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
}
