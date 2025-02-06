

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
        
//         Register for push notifications
        //registerForPushNotifications(application)
        
        return true
    }
    
//    func registerForPushNotifications(_ application: UIApplication) {
//        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
//            if granted {
//                DispatchQueue.main.async {
//                    application.registerForRemoteNotifications()
//                }
//            } else {
//                DispatchQueue.main.async {
//                        application.registerForRemoteNotifications()
//                    }
//            }
//        }
//    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Auth.auth().setAPNSToken(deviceToken, type: .unknown)
        print("APNs token registered: \(deviceToken)")
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if Auth.auth().canHandleNotification(userInfo) {
            print("Firebase Auth handled the notification.")
            completionHandler(.noData)
            return
        }
        
        // Handle other notifications if needed
        print("Received a standard push notification: \(userInfo)")
        completionHandler(.newData)
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


