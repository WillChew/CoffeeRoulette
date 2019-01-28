//
//  AppDelegate.swift
//  CoffeeRoulette
//
//  Created by Will Chew on 2018-07-26.
//  Copyright © 2018 Will Chew. All rights reserved.
//

import UIKit
import CloudKit
import MapKit
import UserNotifications
import ChameleonFramework


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    var event: CKRecord?
    
    
    var databaseManager = DatabaseManager()
    var navigationController: UINavigationController!
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        //GLOBAL THEMING, SEE EXTENSION AT BOTTOM
        //        UIApplication.shared.statusBarStyle = .lightContent
        UINavigationBar.appearance().barTintColor = UIColor.black
        UINavigationBar.appearance().tintColor = UIColor(red:0.96, green:0.96, blue:0.86, alpha:1.0)
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor(red:0.96, green:0.96, blue:0.86, alpha:1.0)]
        configureTheme()
        
        // REMOTE NOTIFICATIONS
        UIApplication.shared.registerForRemoteNotifications()
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (success, error) in
            print(#line, success)
            print(#line, error?.localizedDescription ?? "registered for notifications")
            
            
        }
        
        UNUserNotificationCenter.current().delegate = self
        
        
        
        window = UIWindow()
        
        // UserDefaults.standard.set(false, forKey: "hasLaunched")
        
        
        let hasLaunched = UserDefaults.standard.bool(forKey: "hasLaunched")
        let navigationController: UINavigationController!
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        if (hasLaunched) {
            
            let rootVC = mainStoryboard.instantiateViewController(withIdentifier: "CoffeeRouletteViewController") as! CoffeeRouletteViewController
            navigationController = UINavigationController(rootViewController: rootVC)
            self.window?.rootViewController = navigationController
            
        } else {
            
            
            
            let rootVC = mainStoryboard.instantiateViewController(withIdentifier: "OnboardingPager")
            self.window?.rootViewController = rootVC
            let pageControllerAppearance = UIPageControl.appearance()
            pageControllerAppearance.backgroundColor = UIColor(red:0.3, green:0.3, blue:0.3, alpha:1.0)
        }
        
        window?.makeKeyAndVisible()
        
        return true
    }
    
    func configureTheme() {
        StyleManager.setUpTheme()
    }
}


//MARK - Handle Remote Notifications

extension AppDelegate  {
    
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(#line, "Failed to register: ", error.localizedDescription)
    }
    
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        let notification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        
        print(#line, notification.title ?? "")
        print(#line, notification.alertBody ?? "")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        completionHandler([.alert, .badge, .sound])
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name("guestConfirmed"), object: nil)
        }
        
    }
    
}

