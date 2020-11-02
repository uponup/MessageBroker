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
        
        guard db.open() else { return }

        if db.executeStatements(sqlContacts) {
            print("=====t_contacts 创建成功")
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
     @return [(Contact)]
    */
    static func fetchAllContacts(owner: String) -> [Contact] {
        let sql = "SELECT * FROM t_contacts WHERE owner = ?;"
        guard db.open() else { return [] }
        
        guard let res = try? db.executeQuery(sql, values: [owner]) else { return [] }
        
        var contacts: [Contact] = []
        while res.next() {
            guard let name = res.string(forColumn: "name"),
                let imAccount = res.string(forColumn: "im_account") else { continue }
            contacts.append(Contact(name: name, imAccount: imAccount))
        }
        return contacts
    }
    
    /**
     查找某个好友
     @return Contact
     */
    static func fetchContact(imAccount: String) -> Contact? {
        let sql = "SELECT *FROM t_contacts WHERE im_account = ?;"
        
        guard db.open() else { return nil }
        
        guard let res = try? db.executeQuery(sql, values: [imAccount]) else { return nil }
        
        var contact: Contact? = nil
        while res.next() {
            guard let name = res.string(forColumn: "name"),
                let imAccount = res.string(forColumn: "im_account") else { continue }
            contact = Contact(name: name, imAccount: imAccount)
        }
        return contact
    }
}
