//
//  FirebaseAuthManager.swift
//  Penpal
//
//  Created by Austin William Tucker on 4/8/25.
//

import Foundation
import FirebaseAuth

class FirebaseAuthManager: ObservableObject {
    static let shared = FirebaseAuthManager()
    @Published var currentUser: User?

    private init() {
        LoggerService.shared.log(.info, "Initializing FirebaseAuthManager and adding auth state listener", category: LogCategory.auth)

        Auth.auth().addStateDidChangeListener { _, user in
            DispatchQueue.main.async {
                self.currentUser = user
                if let user = user {
                    LoggerService.shared.log(.info, "User signed in with uid: \(user.uid)", category: LogCategory.auth)
                } else {
                    LoggerService.shared.log(.info, "User signed out", category: LogCategory.auth)
                }
            }
        }
    }

    func signOut() throws {
        do {
            try Auth.auth().signOut()
            LoggerService.shared.log(.info, "User successfully signed out from FirebaseAuth", category: LogCategory.auth)
        } catch {
            LoggerService.shared.log(.error, "Error signing out from FirebaseAuth: \(error.localizedDescription)", category: LogCategory.auth)
            throw error
        }
    }

    func isSignedIn() -> Bool {
        let signedIn = Auth.auth().currentUser != nil
        LoggerService.shared.log(.info, "Checked sign-in status: \(signedIn)", category: LogCategory.auth)
        return signedIn
    }

    func getUserId() -> String? {
        let uid = Auth.auth().currentUser?.uid
        LoggerService.shared.log(.info, "Fetched current user ID: \(uid ?? "nil")", category: LogCategory.auth)
        return uid
    }
}
