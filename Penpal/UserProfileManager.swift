//
//  UserProfileManager.swift
//  Penpal
//
//  Created by Austin William Tucker on 12/2/24.
//


// UserProfileManager.swift
class UserProfileManager {
    static let shared = UserProfileManager()
    
    func fetchUserProfile(userId: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        // Fetch user profile from Firestore or other sources
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                LoggerService.shared.log(.error, "Failed to fetch user profile for userId: \(userId), error: \(error.localizedDescription)", category: LogCategory.firestoreProfile)
                completion(.failure(error))
            } else if let data = snapshot?.data() {
                // Parse and return user profile data
                let profile = UserProfile(data: data)
                LoggerService.shared.log(.info, "Successfully fetched user profile for userId: \(userId)", category: LogCategory.firestoreProfile)
                completion(.success(profile))
            } else {
                LoggerService.shared.log(.warning, "User profile document is empty or missing for userId: \(userId)", category: LogCategory.firestoreProfile)
                completion(.failure(NSError(domain: "UserProfileManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data found for user."])))
            }
        }
    }
}
