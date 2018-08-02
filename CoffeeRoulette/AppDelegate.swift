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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    var databaseManager = DatabaseManager()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    
//        UserDefaults.standard.set(false, forKey: "hasLaunched")
        
        window = UIWindow()
        let hasLaunched = UserDefaults.standard.bool(forKey: "hasLaunched")
        print(hasLaunched)
        
        
        
        if hasLaunched == true {
          
            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let rootVC = mainStoryboard.instantiateViewController(withIdentifier: "CoffeeRouletteViewController") as UIViewController
            let navigationController = UINavigationController(rootViewController: rootVC)
            let attributes = [NSAttributedStringKey.font: UIFont(name: "Noteworthy-Bold", size: 20)!, NSAttributedStringKey.foregroundColor: UIColor(red:0.22, green:0.18, blue:0.11, alpha:1.0)]
            
            let navAppearance = UINavigationBar.appearance()
            navAppearance.titleTextAttributes = attributes
            navAppearance.backgroundColor = .brown
            navAppearance.tintColor = UIColor(red:0.22, green:0.18, blue:0.11, alpha:1.0)
            
            self.window?.rootViewController = navigationController
            
            
        } else {
          
        print("NO")
            let walkthroughVC = UIStoryboard(name: "Main", bundle: nil)
            let rootVC = walkthroughVC.instantiateViewController(withIdentifier: "OnboardingPager")
            self.window?.rootViewController = rootVC
        }
        
        //        databaseManager.getUserID { (recordID, error) in
        //            if error == nil && recordID != nil {
        //                print(recordID!)
        //            }
        //        }
        
        //        if databaseManager.accountStatus == .available {
        //            print("Account status: available")
        //            print(databaseManager.userID!)
        //        } else {
        //            print("Account status: unavailable")
        //        }
        
        window?.makeKeyAndVisible()
        
        
        let pageControllerAppearance = UIPageControl.appearance()
        pageControllerAppearance.backgroundColor = .brown
        

        
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
    
    
}

