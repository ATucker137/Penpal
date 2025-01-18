//
//  PenpalApp.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/28/24.
//

import SwiftUI

@main
struct PenpalApp: App {
    @StateObject private var userSession = UserSession()
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
