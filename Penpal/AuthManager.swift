//
//  AuthManager.swift
//  Penpal
//
//  Created by Austin William Tucker on 12/2/24.
//

import FirebaseAuth

class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isAuthenticated: Bool = false
    @Published var userId: String?

    // Log in with email and password
    func login(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            self?.userId = result?.user.uid
            self?.isAuthenticated = true
            completion(.success(()))
        }
    }

    // Log out the user
    func logout() {
        do {
            try Auth.auth().signOut()
            self.isAuthenticated = false
            self.userId = nil
        } catch {
            print("Error logging out: \(error)")
        }
    }

    // Check current authentication status
    func checkAuthStatus() {
        if let user = Auth.auth().currentUser {
            self.isAuthenticated = true
            self.userId = user.uid
        } else {
            self.isAuthenticated = false
            self.userId = nil
        }
    }
}

