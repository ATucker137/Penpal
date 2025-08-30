//
//  AppDelegate.swift
//  Penpal
//
//  Created by Austin William Tucker on 3/19/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAnalytics
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

        FirebaseApp.configure()

        Analytics.logEvent("app_launch", parameters: [
            "launch_time": Date().description
        ])

        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        requestNotificationPermissions()
        application.registerForRemoteNotifications()

        return true
    }

    private func requestNotificationPermissions() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ Notification permission error: \(error.localizedDescription)")
                return
            }
            if granted {
                print("✅ Notification permissions granted.")
            } else {
                print("❌ Notification permissions denied.")
            }
        }
    }

    // Handle foreground notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    // Handle when a user taps a notification
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        // You can handle navigation or tracking here
        completionHandler()
    }

    // Register device token with Firebase
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        print("Registered with APNs. Token sent to FCM.")
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // Receive the FCM registration token
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        print("🔑 FCM token: \(fcmToken)")
        // Optionally send this token to your server for push targeting
    }

    // Optional: check permissions
    func checkNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            completion(settings.authorizationStatus == .authorized)
        }
    }
}

@main
struct Penpal: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }
    }
}
