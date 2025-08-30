//
//  WelcomePage.swift
//  Penpal
//
//  Created by Austin William Tucker on 12/18/24.
//



/*
 Page  
 What Are You Looking For:
 
 Higher Level, same level
 
 Page for if your open to being selected by people wanting to communicate with you for practice or practice with you out of your target language
 
 Submit Profile - ties to create profile on Firebase
 
 
 */
import SwiftUI

struct WelcomeView: View {
    let onLoginTapped: () -> Void
    let onSignUpTapped: () -> Void
    let onGoogleTapped: (() -> Void)? = nil  // optional

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("Penpal").font(.largeTitle).bold()
            Text("Start your language journey").foregroundStyle(.secondary)

            Button("Log in", action: onLoginTapped)
                .buttonStyle(.borderedProminent)

            Button("Sign up with email", action: onSignUpTapped)
                .buttonStyle(.bordered)

            if let onGoogleTapped {
                Button {
                    onGoogleTapped()
                } label {
                    HStack {
                        Image(systemName: "g.circle") // replace with asset
                        Text("Continue with Google")
                    }
                }
                .buttonStyle(.bordered)
            }
            Spacer()
        }
        .padding()
    }
}

