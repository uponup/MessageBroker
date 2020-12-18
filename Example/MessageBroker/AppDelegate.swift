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
        
        MyTimer().resetDelay(5) {
            print("A")
        }
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
//            print("pre B")
//            MyTimer().resetDelay(5) {
//                print("B")
//            }
//        }
        
        let _ = UserDefaults.executeOnce(withKey: "UpdateDB_8") {
            MessageDao.dropTable()
        }
        
        ContactsDao.createTable()
        GroupsDao.createTable()
        CirclesDao.createTable()
        MessageDao.createTable()
        
        let config = MavlMessageConfiguration(appid: GlobalConfig.xnAppId, appkey: GlobalConfig.xnAppKey, msgKey: GlobalConfig.xnMsgKey, isDebug: true, env: .product, platform: .ios)
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
        
        
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: .alert) { (ret, err) in
            
        }
        UIApplication.shared.registerForRemoteNotifications()
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let pushToken = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        
        MavlMessage.setDeviceToken(tokenString: pushToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Notification 注册失败：\(error.localizedDescription)")
    }

}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print(">>>>>: 收到通知")
        
        if #available(iOS 14.0, *) {
            completionHandler(.banner)
        } else {
            completionHandler(.alert)
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    }
}
