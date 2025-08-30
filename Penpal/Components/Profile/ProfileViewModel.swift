//
//  ProfileViewModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var profile: Profile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var needsOnboarding = true
    // MARK: - Private Properties
    
    private let profileService: ProfileService
    private let category = "Profile ViewModel"


    
    // MARK: - Initalizer
    init(profileService: ProfileService = ProfileService()) {
        self.profileService = profileService
        // Then Fetch Profile?
        //fetchUserProfile(userId: <#T##String#>)
    }
    // MARK: - Check if Profile Exists and Set Flag
    func checkIfProfileExistsAndSetFlag() {
        // Fetch profile for current user; set needsOnboarding = !exists
    }
    // MARK: - Fetch User Profile
    func fetchUserProfile(userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedProfile = try await profileService.fetchProfile(profileId: userId)
            self.profile = fetchedProfile
            
            // Assuming you want to update local cache as well
            if let fetchedProfile = fetchedProfile {
                saveProfileToCache(profile: fetchedProfile)
            }
            
            LoggerService.shared.log(.info, "Profile fetched successfully for userId: \(userId)", category: self.category)
        } catch {
            LoggerService.shared.log(.error, "Failed to fetch profile: \(error)", category: self.category)
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Create User Profile
    func createUserProfile(profile: Profile) async {
        // Step 1: Validate email format
        guard validateEmailFormat(profile.email) else { return }
        
        // Step 2: Check Firebase email verification
        guard let user = Auth.auth().currentUser else {
            self.errorMessage = "You must be logged in to create a profile."
            LoggerService.shared.log(.error, self.errorMessage!, category: self.category)
            return
        }
        
        isLoading = true
        
        do {
            // Use the async version of reload
            try await user.reload()
            
            // Step 3: Block if email not verified
            guard user.isEmailVerified else {
                self.errorMessage = "Please verify your email before creating a profile."
                LoggerService.shared.log(.error, self.errorMessage!, category: self.category)
                isLoading = false
                return
            }
            
            // Step 4: Proceed with profile creation
            LoggerService.shared.log(.info, "Creating profile for userId: \(profile.userId)", category: self.category)
            try await self.profileService.createProfile(profile: profile)
            
            self.profile = profile
            LoggerService.shared.log(.info, "Profile created successfully", category: self.category)
            
        } catch {
            LoggerService.shared.log(.error, "Failed to create profile: \(error)", category: self.category)
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: - Resend Verification Email
    func resendVerificationEmail() async {
        guard let user = Auth.auth().currentUser, !user.isEmailVerified else {
            LoggerService.log("Attempted to resend verification email, but user is already verified or not logged in.", category: .profile)
            return
        }
        
        do {
            try await user.sendEmailVerification()
            self.errorMessage = "Verification email sent. Check your inbox."
            LoggerService.log(" Verification email successfully sent.", category: .profile)
        } catch {
            self.errorMessage = "Could not resend email: \(error.localizedDescription)"
            LoggerService.log("❌ Failed to resend verification email: \(error.localizedDescription)", category: .profile)
        }
    }
    
    // MARK: - Refresh Email Verification Status
    func refreshEmailVerificationStatus() async {
        guard let user = Auth.auth().currentUser else {
            LoggerService.log("Attempted to refresh email verification status, but no user is logged in.", category: .profile)
            return
        }
        
        do {
            try await user.reload()
            if user.isEmailVerified {
                self.errorMessage = "Email verified! You may now create your profile."
                LoggerService.log("✅ Email verification confirmed.", category: .profile)
            } else {
                self.errorMessage = "Still not verified. Check your inbox."
                LoggerService.log("Email still not verified.", category: .profile)
            }
        } catch {
            self.errorMessage = "Could not refresh verification status: \(error.localizedDescription)"
            LoggerService.log("❌ Failed to refresh email verification status: \(error.localizedDescription)", category: .profile)
        }
    }


    
    // MARK: - Update User Profile
    func updateUserProfile(profile: Profile) async {
        isLoading = true
        errorMessage = nil
        LoggerService.shared.log(.info, "Updating profile for userId: \(profile.userId)", category: self.category)
        
        do {
            try await profileService.updateProfile(profile: profile)
            LoggerService.shared.log(.info, "Profile updated successfully", category: self.category)
            self.profile = profile
            
            // Update the local cache after a successful server update
            saveProfileToCache(profile: profile)
        } catch {
            LoggerService.shared.log(.error, "Failed to update profile: \(error)", category: self.category)
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Delete User Profile
    func deleteProfile(profileId: String) async {
        isLoading = true
        LoggerService.shared.log(.info, "Deleting profile with ID: \(profileId)", category: self.category)
        
        do {
            // Step 1: Delete from Firestore
            try await profileService.deleteProfile(profileId: profileId)
            
            // Step 2: Delete from local cache (SQLite) - this is a synchronous function
            SQLiteManager.shared.deleteProfile(for: profileId)
            
            // Optional: clear profile in memory
            self.profile = nil
            self.errorMessage = nil
            LoggerService.shared.log(.info, "Profile deleted from Firestore and cache.", category: self.category)
            
        } catch {
            self.errorMessage = "Failed to delete profile: \(error.localizedDescription)"
            LoggerService.shared.log(.error, self.errorMessage ?? "Unknown error", category: self.category)
        }
        
        isLoading = false
    }
    
    // MARK: - Load profile from local SQLite cache
    func loadProfileFromCache(userId: String) {
        // Attempts to retrieve the profile stored locally in SQLite by userId
        // This allows immediate access to user data without needing an internet connection
        // Useful on app launch or when offline
        if let profile = SQLiteManager.shared.fetchProfile(for: userId) {
            self.profile = profile
            LoggerService.shared.log(.info, "✅ Loaded profile from local cache for userId: \(userId)", category: category)
        } else {
            LoggerService.shared.log(.error, "⚠️ No cached profile found for userId: \(userId)", category: category)
        }
    }

    // MARK: - Save profile to local SQLite cache
    func saveProfileToCache(profile: Profile) {
        // Inserts or updates the profile in the local SQLite cache
        // Called after fetching from Firestore or updating/creating a profile
        // Ensures the local copy stays up to date with the server version
        SQLiteManager.shared.upsertProfile(profile)
        LoggerService.shared.log(.info, "Saved profile to local cache for userId: \(profile.userId)", category: category)

    }

    // MARK: - Sync local SQLite profile to Firestore
    func syncLocalCacheToFirestore() async {
        // Checks if there's a cached profile locally
        // If found, pushes that profile to Firestore using the update logic
        // This is helpful for syncing changes made offline once the network is available
        guard let cached = SQLiteManager.shared.fetchProfile(for: profile?.userId ?? "") else {
            LoggerService.shared.log(.error, "⚠️ No cached profile available to sync to Firestore.", category: category)
            return
        }
        LoggerService.shared.log(.info, "Syncing cached profile to Firestore for userId: \(cached.userId)", category: category)
        // Reuses the existing update flow to send local changes to Firestore
        await updateUserProfile(profile: cached)
    }
    
    // MARK: - Check If Profile Exists Locally
    /// Checks if a profile with the given userId already exists in the local SQLite cache.
    /// Useful for deciding whether to insert or update a profile.
    func profileExistsLocally(userId: String) -> Bool {
        let exists = SQLiteManager.shared.profileExists(for: userId)
        LoggerService.shared.log(.info, "Checked local existence for userId: \(userId) — Exists: \(exists)", category: category)
            return exists    }

    // MARK: - Load Cached Profile
    /// Loads the current user's profile from the local SQLite cache.
    func loadCachedProfile(userId: String) {
        if let cached = SQLiteManager.shared.fetchUserProfile(userId: userId) {
            profile = cached
            LoggerService.shared.log(.info, "✅ Loaded cached profile for userId: \(userId)", category: category)
        } else {
            profile = nil
            LoggerService.shared.log(.error, "⚠️ Failed to load cached profile for userId: \(userId)", category: category)

        }
    }

    // MARK: - Clear Local Cache
    /// Deletes all profiles from the local SQLite cache.
    /// Also clears the in-memory variables. Typically used on logout or full reset.
    func clearLocalProfileCache(userId: String) {
        SQLiteManager.shared.clearProfile(for: userId)
        profile = nil
        LoggerService.shared.log(.info, "Cleared local profile cache for userId: \(userId)", category: category)
    }

    // MARK: - Mark Profile as Synced
    /// Updates the `isSynced` flag of a profile to true after successfully syncing with Firestore.
    /// Helps track whether local changes have been pushed to the server.
    func markProfileAsSynced(userId: String) {
        SQLiteManager.shared.updateSyncStatus(for: userId, isSynced: true)
        LoggerService.shared.log(.info, "✅ Marked profile as synced for userId: \(userId)", category: category)
    }

    // MARK: - Cache Profiles in Bulk
    /// Inserts or updates a single profile in the local SQLite cache.
    /// Updates the in-memory profile after caching.
    func cacheProfile(_ profile: Profile) {
        SQLiteManager.shared.upsertProfile(profile)
        self.profile = profile
        LoggerService.shared.log(.info, "Cached profile locally for userId: \(profile.userId)", category: category)

    }
    
    // MARK: - Refresh User Profile
    /// Forces a fresh fetch of the user's profile from Firestore,
    /// bypassing any cached data. Useful when the profile may have changed
    /// on the server (e.g., after another device updates it).
    /// - Parameter userId: The unique identifier of the user whose profile to fetch.
    func refreshUserProfile(userId: String) {
        LoggerService.shared.log(.info, "Refreshing profile from Firestore for userId: \(userId)", category: category)
        fetchUserProfile(userId: userId)
    }

    // MARK: - Handle Errors Centrally
    /// Handles errors in a consistent way throughout the view model.
    /// Sets the loading state to false, updates the `errorMessage`,
    /// and prints the error to the console for debugging.
    /// - Parameter error: The error to handle.
    private func handleError(_ error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
            LoggerService.shared.log(.error, self.errorMessage ?? "Unknown error", category: self.category)
        }
    }

    // MARK: - Profile Validation
    /// Validates that the profile contains required fields before
    /// allowing it to be saved or updated. Add more checks here as needed.
    /// - Parameter profile: The profile to validate.
    /// - Returns: `true` if the profile is valid; `false` otherwise.
    func isValid(profile: Profile) -> Bool {
        let valid = !profile.firstName.isEmpty &&
                        !profile.email.isEmpty &&
                        validateEmailFormat(profile.email)
            
        LoggerService.shared.log(.info, "Profile validation for userId: \(profile.userId) — Valid: \(valid)", category: category)
        return valid
    }
    
    private func validateEmailFormat(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let isValid = NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
        
        if !isValid {
            errorMessage = "Please enter a valid email address."
            LoggerService.shared.log(.error, "❌ Invalid email format: \(email)", category: category)
        } else {
            errorMessage = nil
            LoggerService.shared.log(.info, "✅ Valid email format: \(email)", category: category)
        }

        return isValid
    }

    // MARK: - Basic Password Validation
    func isValidPassword(_ password: String) -> Bool {
        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters long."
            LoggerService.shared.log(.error, errorMessage ?? "Password too short", category: category)
            return false
        }
        let uppercaseLetterRegEx = ".*[A-Z]+.*"
        let numberRegEx = ".*[0-9]+.*"
        let uppercaseTest = NSPredicate(format:"SELF MATCHES %@", uppercaseLetterRegEx)
        let numberTest = NSPredicate(format:"SELF MATCHES %@", numberRegEx)
        
        let valid = uppercaseTest.evaluate(with: password) && numberTest.evaluate(with: password)
        if !valid {
            errorMessage = "Password must contain at least one uppercase letter and one number."
            LoggerService.shared.log(.error, errorMessage ?? "Invalid password format", category: category)
        } else {
            errorMessage = nil
            LoggerService.shared.log(.info, "✅ Password passed validation", category: category)
        }
        return valid
    }
}
