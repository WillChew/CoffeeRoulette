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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    var event: CKRecord?

    
    var databaseManager = DatabaseManager()
    var navigationController: UINavigationController!
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    
        //GLOBAL THEMING, SEE EXTENSION AT BOTTOM
        UIApplication.shared.statusBarStyle = .lightContent
//        UINavigationBar.appearance().barTintColor = UIColor(red: 234.0/255.0, green: 46.0/255.0, blue: 73.0/255.0, alpha: 1.0)
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white]
        configureTheme()
        
        // REMOTE NOTIFICATIONS
        UIApplication.shared.registerForRemoteNotifications()
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (success, error) in
            print(#line, success)
            print(#line, error?.localizedDescription ?? "registered for notifications")
            
        
        }
        


        window = UIWindow()
        
        // UserDefaults.standard.set(false, forKey: "hasLaunched")
        
        
        let hasLaunched = UserDefaults.standard.bool(forKey: "hasLaunched")
        let navigationController: UINavigationController!
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        if (hasLaunched) {
            
            
            
            if (false) {
//                let eventDetailsViewController = mainStoryboard.instantiateViewController(withIdentifier: "EventDetailsViewController") as! EventDetailsViewController
//                eventDetailsViewController.event = event
//                self.window?.rootViewController = eventDetailsViewController
                
            } else {
                //let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let rootVC = mainStoryboard.instantiateViewController(withIdentifier: "CoffeeRouletteViewController") as! CoffeeRouletteViewController
                navigationController = UINavigationController(rootViewController: rootVC)
                let attributes = [NSAttributedStringKey.font: UIFont(name: "Noteworthy-Bold", size: 20)!, NSAttributedStringKey.foregroundColor: UIColor(red:0.22, green:0.18, blue:0.11, alpha:1.0)]
                
                let navAppearance = UINavigationBar.appearance()
                navAppearance.titleTextAttributes = attributes
                navAppearance.backgroundColor = .brown
                navAppearance.tintColor = UIColor(red:0.22, green:0.18, blue:0.11, alpha:1.0)
                
                self.window?.rootViewController = navigationController
            }

        } else {
            print("NO")
            
//            let walkthroughVC = UIStoryboard(name: "Main", bundle: nil)
            let rootVC = mainStoryboard.instantiateViewController(withIdentifier: "OnboardingPager")
            self.window?.rootViewController = rootVC
            
            let attributes = [NSAttributedStringKey.font: UIFont(name: "Noteworthy-Bold", size: 20)!, NSAttributedStringKey.foregroundColor: UIColor(red:0.22, green:0.18, blue:0.11, alpha:1.0)]
            
            let navAppearance = UINavigationBar.appearance()
            navAppearance.titleTextAttributes = attributes
            navAppearance.backgroundColor = .brown
            navAppearance.tintColor = UIColor(red:0.22, green:0.18, blue:0.11, alpha:1.0)
            
            // note the fact that app has been launched
            // UserDefaults.standard.set(true, forKey: "hasLaunched")
            let pageControllerAppearance = UIPageControl.appearance()
            pageControllerAppearance.backgroundColor = .brown
        }
        

        window?.makeKeyAndVisible()
        
        
 
        return true
    }
}



//MARK - Handle Remote Notifications

extension AppDelegate  {

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
 
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(#line, "Failed to register: ", error.localizedDescription)
    }
    
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        let notification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        
//        if (notification.subscriptionID == "x" + userID!) {
//
//        }
        
        print(#line, notification.title ?? "")
        print(#line, notification.alertBody ?? "")   
    }

}

extension AppDelegate {
    
    func configureTheme() {
        StyleManager.setUpTheme()
    
    }
}
