//
//  LoginView.swift
//  Penpal
//
//  Created by Austin William Tucker on 7/28/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var userSession: UserSession

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var focused: Field?
    enum Field { case email, password }

    var onSignupTapped: (() -> Void)? // optional link to signup

    var body: some View {
        VStack(spacing: 16) {
            Text("Log in to Penpal").font(.title2).bold()

            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textFieldStyle(.roundedBorder)
                .focused($focused, equals: .email)
                .submitLabel(.next)
                .onSubmit { focused = .password }

            SecureField("Password", text: $password)
                .textContentType(.password)
                .textFieldStyle(.roundedBorder)
                .focused($focused, equals: .password)
                .submitLabel(.go)
                .onSubmit { login() }

            if let errorMessage { Text(errorMessage).foregroundColor(.red).font(.footnote) }

            Button(action: login) {
                Group {
                    if isLoading { ProgressView() }
                    else { Text("Log In").bold() }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading || email.isEmpty || password.isEmpty)

            if let onSignupTapped {
                Button("Create an account", action: onSignupTapped)
                    .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Log In")
    }

    private func login() {
        errorMessage = nil
        isLoading = true
        AuthManager.shared.login(email: email, password: password) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success:
                    if let u = AuthManager.shared.currentUser {
                        userSession.saveSession(
                            userId: u.uid,
                            email: u.email ?? "",
                            userName: nil,
                            profileImageURL: nil
                        )
                        // ContentView will now re-evaluate and route to
                        // OnboardingFlow or MainTabView.
                    }
                case .failure(let err):
                    errorMessage = err.localizedDescription
                }
            }
        }
    }
}
