//
//  AppDelegate.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/9/21.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let _ = UserDefaults.executeOnce(withKey: "UpdateDB_8") {
            MessageDao.dropTable()
        }
        
        ContactsDao.createTable()
        GroupsDao.createTable()
        CirclesDao.createTable()
        MessageDao.createTable()
        
        let config = MavlMessageConfiguration(appid: GlobalConfig.xnAppId, appkey: GlobalConfig.xnAppKey, msgKey: GlobalConfig.xnMsgKey)
        MavlMessage.shared.initializeSDK(config: config)
        
        Thread.sleep(forTimeInterval: 1)
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.backgroundColor = UIColor.white
        if #available(iOS 13.0, *) {
            let tabbar = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "TabbarController")
            self.window?.rootViewController = tabbar
        } else {
            // Fallback on earlier versions
            let tabbar = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TabbarController")
            self.window?.rootViewController = tabbar
        }
        
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let pushToken = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print(pushToken)
        
        MavlMessage.setDeviceToken(tokenString: pushToken)
    }

}
