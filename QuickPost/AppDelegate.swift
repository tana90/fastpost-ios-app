//
//  AppDelegate.swift
//  FastPost
//
//  Created by Tudor Ana on 5/23/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    let token = AppManager.initApp()
    
    static let shared: AppDelegate = {
        let instance = AppDelegate()
        return instance
    }()
    
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        //Load appstore IAP
        PROUpgradeProduct.store.requestProducts { (success, products) in
            po(products)
            if success {
                guard let _ = products,
                    (products?.count)! > 0 else { return }
                CachedPrice = priceStringForProduct(item: (products?.first)!)!
            }
        }
        
        
        if !UserDefaults.standard.bool(forKey: "AUTHENTICATED") {
            allowAutoSelect = false
            Connector.shared.registerUser(with: self.token) { (json) in

                if let _ = json?.dictionary,
                    let status = json?.dictionary!["status"]?.string,
                    status == "0" {
                    UserDefaults.standard.set(true, forKey: "AUTHENTICATED")
                    
                    DispatchQueue.main.safeAsync { [weak self] in
                        guard let _ = self else { return }
                        let center = UNUserNotificationCenter.current()
                        center.delegate = self!
                        center.requestAuthorization(options: [.alert, .sound, .badge]) {
                            (granted, error) in

                            if granted {
                                DispatchQueue.main.safeAsync {
                                    application.registerForRemoteNotifications()
                                }
                            }
                        }
                    }
                    
                    
                }
            }
        }
        
        
        if !PROVersion {
            AdManager.shared.enable()
        } else {
            AdManager.shared.disable()
        }
        
        
        //Set time interval between App Background Refreshes
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        

        return true
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

        var deviceId = String(format: "%@", deviceToken as CVarArg)
        deviceId = deviceId.replacingOccurrences(of: "<", with: "")
        deviceId = deviceId.replacingOccurrences(of: ">", with: "")
        deviceId = deviceId.replacingOccurrences(of: " ", with: "")
        
        Connector.shared.registerDevice(with: self.token, with: deviceId) { (json) in
        }
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        AppManager.shared.loadSettings { (finished) in
            po("Update from receive remote notif")
            completionHandler(.newData)
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        EventHandler.shared.openFavorites()
        return true
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        AppManager.shared.loadSettings { (finished) in
            po("Update from fetch")
            completionHandler(.newData)
        }
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
        RepostManager.shared.checkClipboard()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
        RepostManager.shared.checkClipboard()
    }

}

