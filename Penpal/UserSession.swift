//
//  UserSession.swift
//  Penpal
//
//  Created by Austin William Tucker on 12/2/24.
//



import Foundation
import Combine

class UserSession: ObservableObject {
    static let shared = UserSession() // Singleton instance
    
    @Published var userId: String?
    @Published var email: String?
    @Published var userName: String?
    @Published var profileImageURL: String?
    @Published var isLoggedIn: Bool = false
    
    private init() {
        // Optionally load saved session data from persistent storage (e.g., UserDefaults or Keychain)
        loadSession()
    }
    
    // Save user session details
    func saveSession(userId: String, email: String, userName: String? = nil, profileImageURL: String? = nil) {
        self.userId = userId
        self.email = email
        self.userName = userName
        self.profileImageURL = profileImageURL
        self.isLoggedIn = true
        
        // Save to persistent storage
        saveToPersistentStorage()
    }
    
    // Clear user session
    func clearSession() {
        self.userId = nil
        self.email = nil
        self.userName = nil
        self.profileImageURL = nil
        self.isLoggedIn = false
        
        // Remove from persistent storage
        clearFromPersistentStorage()
    }
    
    // Load session data from persistent storage
    private func loadSession() {
        if let storedUserId = UserDefaults.standard.string(forKey: "userId"),
           let storedEmail = UserDefaults.standard.string(forKey: "email") {
            self.userId = storedUserId
            self.email = storedEmail
            self.userName = UserDefaults.standard.string(forKey: "userName")
            self.profileImageURL = UserDefaults.standard.string(forKey: "profileImageURL")
            self.isLoggedIn = true
        }
    }
    
    // Save session data to persistent storage
    private func saveToPersistentStorage() {
        UserDefaults.standard.set(userId, forKey: "userId")
        UserDefaults.standard.set(email, forKey: "email")
        UserDefaults.standard.set(userName, forKey: "userName")
        UserDefaults.standard.set(profileImageURL, forKey: "profileImageURL")
    }
    
    // Clear session data from persistent storage
    private func clearFromPersistentStorage() {
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "email")
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "profileImageURL")
    }
    
    // MARK: - Logout and Clear All User Data
    /// Logs out the user, clears session, and removes any cached local data.
    /// This ensures no old user data persists if another user logs in on the same device.
    func logoutAndClearUserData() {
        // Sign out from Firebase
        do {
            try FirebaseAuthManager.shared.signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
        
        // Clear session state
        clearSession()
        
        // Clear any local storage for
        // Clear local SQLite cache (Conversations, Messages, Meetings, MyCalendar, VocabSheets, VocabCards, Profiles)
        SQLiteManager.shared.clearAllLocalCaches()
        // isLoggedIn will already be set to false by clearSession()
    }

}
