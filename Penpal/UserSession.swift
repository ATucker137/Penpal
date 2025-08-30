//
//  UserSession.swift
//  Penpal
//
//  Created by Austin William Tucker on 12/2/24.
//



import Foundation
import Combine
import FirebaseAuth

class UserSession: ObservableObject {
    static let shared = UserSession() // Singleton instance
    
    @Published var userId: String?
    @Published var email: String?
    @Published var userName: String?
    @Published var profileImageURL: String?
    @Published var isLoggedIn: Bool = false
    private var cancellables = Set<AnyCancellable>()

    
    private init() {
        // Optionally load saved session data from persistent storage (e.g., UserDefaults or Keychain)
        loadSession()
        observeAuthState()

    }
    
    // Subscribe to FirebaseAuthManager’s currentUser publisher
    private func observeAuthState() {
        FirebaseAuthManager.shared.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                guard let self = self else { return }
                
                if let user = user {
                    self.userId = user.uid
                    self.email = user.email
                    self.isLoggedIn = true
                    LoggerService.shared.log(.info, "✅ UserSession updated with userId: \(user.uid)", category: LogCategory.auth)
                    self.saveToPersistentStorage()
                } else {
                    self.clearSession()
                    LoggerService.shared.log(.info, "🔒 UserSession cleared after logout", category: LogCategory.auth)
                }
            }
            .store(in: &cancellables)
    }
    
    // Save user session details
    func saveSession(userId: String, email: String, userName: String? = nil, profileImageURL: String? = nil) {
        self.userId = userId
        self.email = email
        self.userName = userName
        self.profileImageURL = profileImageURL
        self.isLoggedIn = true
        LoggerService.shared.log(.info, "✅ Session saved for userId: \(userId)", category: LogCategory.auth)
        // Save to persistent storage
        saveToPersistentStorage()
    }
    
    // Clear user session
    func clearSession() {
        LoggerService.shared.log(.info, "Clearing session data", category: LogCategory.auth)
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
            LoggerService.shared.log(.info, "✅ Loaded session from storage for userId: \(storedUserId)", category: LogCategory.auth)
        } else {
            LoggerService.shared.log(.info, "No existing session found in storage", category: LogCategory.auth)
        }
    }
    
    // Save session data to persistent storage
    private func saveToPersistentStorage() {
        UserDefaults.standard.set(userId, forKey: "userId")
        UserDefaults.standard.set(email, forKey: "email")
        UserDefaults.standard.set(userName, forKey: "userName")
        UserDefaults.standard.set(profileImageURL, forKey: "profileImageURL")
        LoggerService.shared.log(.info, "Saved session data to UserDefaults", category: LogCategory.auth)

    }
    
    // Clear session data from persistent storage
    private func clearFromPersistentStorage() {
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "email")
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "profileImageURL")
        LoggerService.shared.log(.info, "Cleared session data from UserDefaults", category: LogCategory.auth)

    }
    
    // MARK: - Logout and Clear All User Data
    /// Logs out the user, clears session, and removes any cached local data.
    /// This ensures no old user data persists if another user logs in on the same device.
    func logoutAndClearUserData() {
        // Sign out from Firebase
        do {
            try FirebaseAuthManager.shared.signOut()
            LoggerService.shared.log(.info, "✅ Firebase sign-out successful", category: LogCategory.auth)

        } catch {
            LoggerService.shared.log(.error, "❌ Firebase sign-out failed: \(error.localizedDescription)", category: LogCategory.auth)
        }
        
        // Clear session state
        clearSession()
        
        // Clear any local storage for
        // Clear local SQLite cache (Conversations, Messages, Meetings, MyCalendar, VocabSheets, VocabCards, Profiles)
        SQLiteManager.shared.clearAllLocalCaches()
        // isLoggedIn will already be set to false by clearSession()
        LoggerService.shared.log(.info, "Local SQLite caches cleared after logout", category: LogCategory.auth)

    }

}
