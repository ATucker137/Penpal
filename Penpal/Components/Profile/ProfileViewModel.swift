//
//  ProfileViewModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//
//
//  ProfileViewModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//

class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var profile: Profile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let profileService = ProfileService
    
    
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
        isLoading = true
        errorMessage = nil
        
        profileService.createProfile(profile: profile) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.profile = profile // Save the newly created profile
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
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
    
    func deleteUserProfile(profile: Profile) {
        isLoading = true
        errorMessage = nil

        profileService.deleteProfile(profile: profile) { [weak self] result in
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
}
