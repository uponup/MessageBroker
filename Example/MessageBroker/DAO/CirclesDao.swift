//
//  CirclesDao.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/11/2.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import Foundation


/**
 圈子的数据库
 采用vmuc，创建虚拟群组。在IM后台不保存圈子的信息，
 
 circleId 信息由业务层自行维护
 */
struct CirclesDao {
    static let db = SQLiteManager.sharedManager().db

    static func createTable() {
        let sqlGroups = "CREATE TABLE IF NOT EXISTS t_circles (circleId VARCHAR(32) PRIMARY KEY, users TEXT, title VARCHAR(32), owner VARCHAR(32));"

        guard db.open() else { return }
        
        if db.executeStatements(sqlGroups) {
            print("=====t_circles 创建成功")
        }else {
            print("=====t_circles 创建失败")
        }
    }
    static func dropTable() {
        guard db.open() else { return }
        let sql = "DROP TABLE t_circles;"
        if db.executeStatements(sql) {
            print("=====t_circles 删除成功")
        }else {
            print("=====t_circles 删除失败")
        }
    }
}

extension CirclesDao {
    /**
     加入圈子
     */
    static func joinCircles(vmucId: String = UUID().uuidString, users: [String], owner: String) -> Circle? {
        guard db.open() else { return nil }
        
        let sql = "INSERT INTO t_circles VALUES (?, ?, ?, ?);"
                
        let circle = Circle(name: "新圈子-\(vmucId[vmucId.count-6..<vmucId.count])", vmucId: vmucId, users: users.joined(separator: "_"))
        
        if db.executeUpdate(sql, withArgumentsIn: [circle.vmucId, circle.users, circle.name, owner]) {
            print("加入圈子成功：\(vmucId)")
            return circle
        }else {
            print("加入圈子失败：\(vmucId)")
            return nil
        }
    }
    
    static func quitCircles(vmucId: String) {
        guard db.open() else { return }
        
        let sql = "DELETE FROM t_circles WHERE circleId = ?;"
        if db.executeUpdate(sql, withArgumentsIn: [vmucId]) {
            print("退出圈子成功：\(vmucId)")
        }else {
            print("退出圈子成功：\(vmucId)")
        }
    }
    
    static func updateCircle(name n: String, vmucId: String) {
        guard db.open() else { return }

        let sql = "UPDATE t_circles SET title = ? WHERE circleId = ?;"
        if db.executeUpdate(sql, withArgumentsIn: [n, vmucId]) {
            print("修改圈子成功：\(vmucId)，名称：\(n)")
        }else {
            print("修改圈子失败：\(vmucId)，名称：\(n)")
        }
    }
    
    /**
     查找所有圈子
     返回（circleId, 用户列表，圈子名称）
     */
    static func fetchAllCircles(owner: String) -> [Circle] {
        guard db.open() else { return [] }
        
        let sql = "SELECT *FROM t_circles WHERE owner = ?;"
        guard let res = db.executeQuery(sql, withArgumentsIn: [owner]) else { return [] }
        
        var circles: [Circle] = []
        while res.next() {
            let vmucId = res.string(forColumn: "circleId").value
            let users = res.string(forColumn: "users").value
            let name = res.string(forColumn: "title").value
            
            circles.append(Circle(name: name, vmucId: vmucId, users: users))
        }
        return circles
    }
    
    /**
        查找某个圈子的所有用户
     */
    static func fetchAllMembers(fromCircle circleId: String) -> [String] {
        guard db.open() else { return [] }
        
        let sql = "SELECT users FROM t_circles WHERE circleId = ?;"
        guard let res = db.executeQuery(sql, withArgumentsIn: [circleId]) else { return [] }
        
        var members: [String] = []
        while res.next() {
            let circleUsers = res.string(forColumn: "users").value
            members = circleUsers.split(separator: "_").map{ String($0) }
        }
        return members
    }
    
    /**
     查找某个圈子信息
     */
    static func fetchCircle(circleId: String) -> Circle? {
        let sql = "SELECT * FROM t_circles WHERE circleId = ?;"
        guard db.open() else { return nil }
        
        guard let res = try? db.executeQuery(sql, values: [circleId]) else { return nil }
        
        var circle: Circle? = nil
        while res.next() {
            let vmucId = res.string(forColumn: "circleId").value
            let users = res.string(forColumn: "users").value
            let name = res.string(forColumn: "title").value
            
            circle = Circle(name: name, vmucId: vmucId, users: users)
        }
        return circle
    }
}
