//
//  AppDelegate.swift
//  CyberGrid
//
//  Created by Robert Haynes on 30/12/2024.
//

import UIKit
import GoogleMobileAds

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        if LeaderboardManager.shared.getElo() == 0 { LeaderboardManager.shared.setElo(1000) }
        if UserDefaults.standard.integer(forKey: "numOfMoves") == 0 { UserDefaults.standard.set(6, forKey: "numOfMoves") }
        
        MobileAds.shared.start(completionHandler: nil)
        Task {
            await Store.shared.loadProducts()
            print("Products Downloaded: \(Store.shared.products)")
        }
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

