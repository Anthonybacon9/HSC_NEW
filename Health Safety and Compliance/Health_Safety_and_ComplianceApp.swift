

//
//  Health_Safety_and_ComplianceApp.swift
//  Health Safety and Compliance
//
//  Created by Anthony Bacon on 03/10/2024.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        if Auth.auth().canHandleNotification(userInfo) {
            print("Firebase Auth handled the notification.")
            return
        }
        // Handle other notifications if needed
        print("This is a regular push notification.")
    }
}
@main
struct Health_Safety_and_ComplianceApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
        }
    }
}


