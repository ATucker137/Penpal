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
        Auth.auth().addStateDidChangeListener { _, user in
            DispatchQueue.main.async {
                self.currentUser = user
            }
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func isSignedIn() -> Bool {
        return Auth.auth().currentUser != nil
    }

    func getUserId() -> String? {
        return Auth.auth().currentUser?.uid
    }
}
