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
                completion(.failure(error))
            } else if let data = snapshot?.data() {
                // Parse and return user profile data
                let profile = UserProfile(data: data)
                completion(.success(profile))
            }
        }
    }
}
