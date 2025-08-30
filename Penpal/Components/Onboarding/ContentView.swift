//
//  ContentView.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/28/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var userSession: UserSession
    @StateObject private var profileVM  = ProfileViewModel()
    @StateObject private var messagesVM = MessagesViewModel()
    @StateObject private var penpalsVM  = PenpalsViewModel()

    var body: some View {
        Group {
            if !userSession.isLoggedIn {
                // 1) Logged out
                LoginView()
            } else if profileVM.needsOnboarding {
                // 2) Logged in but profile missing → Onboarding
                OnboardingView(profileVM: profileVM) {
                    // Onboarding finished callback
                    profileVM.needsOnboarding = false
                }
                .environmentObject(profileVM)
            } else {
                // 3) Logged in and ready → Main app
                MainTabView()
                    .environmentObject(profileVM)
                    .environmentObject(messagesVM)
                    .environmentObject(penpalsVM)
            }
        }
        .onAppear {
            userSession.loadSession()
            // If already logged in on launch, decide whether onboarding is needed
            if userSession.isLoggedIn {
                profileVM.checkIfProfileExistsAndSetFlag()
            }
        }
        .onChange(of: userSession.isLoggedIn) { loggedIn in
            if loggedIn {
                // After a fresh login, decide whether to show onboarding
                profileVM.checkIfProfileExistsAndSetFlag()
            } else {
                // Optional: reset per-login state here
            }
        }
        .animation(.default, value: userSession.isLoggedIn)
        .transition(.opacity)
    }
}
