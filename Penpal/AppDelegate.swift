//
//  AppDelegate.swift
//  Penpal
//
//  Created by Austin William Tucker on 3/19/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAnalytics


class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
      
      // Log an event when the app is launched (e.g., for analytics)
      Analytics.logEvent("app_launch", parameters: [
        "launch_time": Date().description
      ])

    return true
  }
}

@main
struct Penpal: App {
  // register app delegate for Firebase setup
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate


  var body: some Scene {
    WindowGroup {
      NavigationView {
        ContentView()
      }
    }
  }
}
