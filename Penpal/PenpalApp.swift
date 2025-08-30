//
//  PenpalApp.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/28/24.
//

import SwiftUI
import Firebase
@main
struct PenpalApp: App {
    @StateObject private var userSession = UserSession.shared  
    init() {
        // Initialize Firebase
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userSession)
        }
    }
}
