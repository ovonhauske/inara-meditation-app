//
//  AppDelegate.swift
//  inara
//
//  Created by Assistant on 1/2/26.
//

import UIKit
import FirebaseCore

@MainActor
class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Configure Firebase if it hasn't been configured yet
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        print("Firebase configured: \(FirebaseApp.app() != nil)")
        return true
    }
}

