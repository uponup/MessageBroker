//
//  SQLiteManager.swift
//  BookBoy
//
//  Created by 龙格 on 2020/3/19.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import Foundation
import FMDB

class SQLiteManager: NSObject {
    private static let manager: SQLiteManager = SQLiteManager()
    private let dbName = "record.db"
    
    class func sharedManager() -> SQLiteManager {
        return manager
    }
    
    lazy var dbURL: URL = {
        let fileURL = try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(dbName)
        return fileURL
    }()
    
    lazy var db: FMDatabase = {
        let database = FMDatabase(url: dbURL)
        return database
    }()
    
    lazy var dbQueue: FMDatabaseQueue? = {
        let databaseQueue = FMDatabaseQueue(url: dbURL)
        return databaseQueue
    }()
    
    func destory() {
        db = FMDatabase(url: dbURL)
        dbQueue = nil
    }
}

extension SQLiteManager {
    static var size: Float {
        let manager = FileManager.default
        let filePath = self.manager.dbURL.path
        
        guard manager.fileExists(atPath: filePath) else { return 0 }
        
        if let dic = try? manager.attributesOfItem(atPath: filePath) {
            return dic[FileAttributeKey.size] as! Float
        }
        return 0
    }
    
}
