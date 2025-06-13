//
//  ProfileViewModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//
//


class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var profile: Profile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let profileService: ProfileService

    
    // MARK: - Initalizer
    init(profileService: ProfileService = ProfileService()) {
        self.profileService = profileService
        // Then Fetch Profile?
        //fetchUserProfile(userId: <#T##String#>)
    }
    
    
    
    // MARK: - Fetch User Profile
    func fetchUserProfile(userId: String) {
        isLoading = true
        errorMessage = nil
        
        profileService.fetchProfile(profileId: userId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let profile):
                    self?.profile = profile
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription // Ensure proper error handling
                }
            }
        }
    }
    
    // MARK: - Create User Profile
    func createUserProfile(profile: Profile) {
        
        // Step 1: Validate email format
        guard validateEmailFormat(profile.email) else {
            errorMessage = "Please enter a valid email."
            return
        }
        
        // Step 2: Check Firebase email verification
        guard let user = Auth.auth().currentUser else {
            errorMessage = "You must be logged in to create a profile."
            return
        }
        
        user.reload { [weak self] _ in
            guard let self = self else { return }
            
            // Step 3: Block if email not verified
            guard user.isEmailVerified else {
                DispatchQueue.main.async {
                    self.errorMessage = "Please verify your email before creating a profile."
                }
                return
            }

            // Step 4: Proceed with profile creation
            DispatchQueue.main.async {
                self.isLoading = true
                self.errorMessage = nil
            }
            
            self.profileService.createProfile(profile: profile) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    switch result {
                    case .success:
                        self.profile = profile
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    func resendVerificationEmail() {
        guard let user = Auth.auth().currentUser, !user.isEmailVerified else { return }
        
        user.sendEmailVerification { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Could not resend email: \(error.localizedDescription)"
                } else {
                    self?.errorMessage = "Verification email sent. Check your inbox."
                }
            }
        }
    }
    
    func refreshEmailVerificationStatus() {
        guard let user = Auth.auth().currentUser else { return }

        user.reload { [weak self] error in
            if let error = error {
                self?.errorMessage = "Could not refresh verification status: \(error.localizedDescription)"
            } else if user.isEmailVerified {
                self?.errorMessage = "Email verified! You may now create your profile."
            } else {
                self?.errorMessage = "Still not verified. Check your inbox."
            }
        }
    }


    
    // MARK: - Update User Profile
    func updateUserProfile(profile: Profile) {
        isLoading = true
        errorMessage = nil

        profileService.updateProfile(profile: profile) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.profile = profile // Update the profile in memory
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Delete User Profile
    func deleteProfile(profileId: String) {
        // Optional: set loading state
        isLoading = true

        // Step 1: Delete from Firestore
        profileService.deleteProfile(profileId: profileId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Step 2: Delete from local cache (SQLite)
                    SQLiteManager.shared.deleteProfile(for: profileId)
                    // Optional: clear profile in memory
                    self?.profile = nil
                    self?.errorMessage = nil
                    print("✅ Profile deleted from Firestore and local cache.")
                case .failure(let error):
                    self?.errorMessage = "Failed to delete profile: \(error.localizedDescription)"
                    print("❌ Delete failed: \(error)")
                }
                self?.isLoading = false
            }
        }
    }
    
    // MARK: - Load profile from local SQLite cache
    func loadProfileFromCache(userId: String) {
        // Attempts to retrieve the profile stored locally in SQLite by userId
        // This allows immediate access to user data without needing an internet connection
        // Useful on app launch or when offline
        self.profile = SQLiteManager.shared.fetchProfile(for: userId)
    }

    // MARK: - Save profile to local SQLite cache
    func saveProfileToCache(profile: Profile) {
        // Inserts or updates the profile in the local SQLite cache
        // Called after fetching from Firestore or updating/creating a profile
        // Ensures the local copy stays up to date with the server version
        func saveProfileToCache(profile: Profile) {
            SQLiteManager.shared.upsertProfile(profile)
        }
    }

    // MARK: - Sync local SQLite profile to Firestore
    func syncLocalCacheToFirestore() {
        // Checks if there's a cached profile locally
        // If found, pushes that profile to Firestore using the update logic
        // This is helpful for syncing changes made offline once the network is available
        guard let cached = SQLiteManager.shared.fetchProfile(for: profile?.userId ?? "") else { return }
        
        // Reuses the existing update flow to send local changes to Firestore
        updateUserProfile(profile: cached)
    }
    
    // MARK: - Check If Profile Exists Locally
    /// Checks if a profile with the given userId already exists in the local SQLite cache.
    /// Useful for deciding whether to insert or update a profile.
    func profileExistsLocally(userId: String) -> Bool {
        return SQLiteManager.shared.profileExists(for: userId)
    }

    // MARK: - Load Cached Profile
    /// Loads the current user's profile from the local SQLite cache.
    func loadCachedProfile(userId: String) {
        if let cached = SQLiteManager.shared.fetchUserProfile(userId: userId) {
            profile = cached
        } else {
            print("Failed to load cached profile for userId: \(userId)")
            profile = nil
        }
    }

    // MARK: - Clear Local Cache
    /// Deletes all profiles from the local SQLite cache.
    /// Also clears the in-memory variables. Typically used on logout or full reset.
    func clearLocalProfileCache(userId: String) {
        SQLiteManager.shared.clearProfile(for: userId)
        profile = nil
    }

    // MARK: - Mark Profile as Synced
    /// Updates the `isSynced` flag of a profile to true after successfully syncing with Firestore.
    /// Helps track whether local changes have been pushed to the server.
    func markProfileAsSynced(userId: String) {
        SQLiteManager.shared.updateSyncStatus(for: userId, isSynced: true)
    }

    // MARK: - Cache Profiles in Bulk
    /// Inserts or updates a single profile in the local SQLite cache.
    /// Updates the in-memory profile after caching.
    func cacheProfile(_ profile: Profile) {
        SQLiteManager.shared.upsertProfile(profile)
        self.profile = profile
    }
    
    // MARK: - Refresh User Profile
    /// Forces a fresh fetch of the user's profile from Firestore,
    /// bypassing any cached data. Useful when the profile may have changed
    /// on the server (e.g., after another device updates it).
    /// - Parameter userId: The unique identifier of the user whose profile to fetch.
    func refreshUserProfile(userId: String) {
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
            print("❌ Profile Error: \(error.localizedDescription)")
        }
    }

    // MARK: - Profile Validation
    /// Validates that the profile contains required fields before
    /// allowing it to be saved or updated. Add more checks here as needed.
    /// - Parameter profile: The profile to validate.
    /// - Returns: `true` if the profile is valid; `false` otherwise.
    func isValid(profile: Profile) -> Bool {
        return !profile.firstName.isEmpty &&
                   !profile.email.isEmpty &&
        validateEmailFormat(profile.email)
    }
    
    private func validateEmailFormat(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
            let isValid = NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
            
            if !isValid {
                errorMessage = "Please enter a valid email address."
            } else {
                errorMessage = nil
            }
            
            return isValid
    }

    // MARK: - Basic Password Validation
    func isValidPassword(_ password: String) -> Bool {
        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters long."
            return false
        }
        let uppercaseLetterRegEx = ".*[A-Z]+.*"
        let numberRegEx = ".*[0-9]+.*"
        let uppercaseTest = NSPredicate(format:"SELF MATCHES %@", uppercaseLetterRegEx)
        let numberTest = NSPredicate(format:"SELF MATCHES %@", numberRegEx)
        
        let valid = uppercaseTest.evaluate(with: password) && numberTest.evaluate(with: password)
        if !valid {
            errorMessage = "Password must contain at least one uppercase letter and one number."
        } else {
            errorMessage = nil
        }
        return valid
    }





}
