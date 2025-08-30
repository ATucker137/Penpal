//
//  ProfileService.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//
import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift


// TODO: List Under
/*
 Real Time Updates
 Batch Operation
 Firestore Security Rules
 
 Pagination
 
 Profile Image Handling
 Testing - Unit Testing Within Service Layer

*/
import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

class ProfileService {
    private let db = Firestore.firestore()
    private let collectionName = "profiles"
    private let category = "profileService"


    // MARK: - Create Profile
    func createProfile(profile: Profile) async throws {
        do {
            // Use the async version of setData with from:
            try await db.collection(collectionName).document(profile.id).setData(from: profile)
            LoggerService.shared.log(.info, "✅ Successfully created profile for userId: \(profile.id)", category: self.category)
        } catch {
            LoggerService.shared.log(.error, "❌ Failed to create profile: \(error.localizedDescription)", category: self.category)
            throw error
        }
    }

    // MARK: - Update Profile
    func updateProfile(profile: Profile) async throws {
        do {
            // Use the async version of setData with merge: true
            try await db.collection(collectionName).document(profile.id).setData(from: profile, merge: true)
            LoggerService.shared.log(.info, "✅ Successfully updated profile for userId: \(profile.id)", category: self.category)
        } catch {
            LoggerService.shared.log(.error, "❌ Failed to update profile: \(error.localizedDescription)", category: self.category)
            throw error
        }
    }

    // MARK: - Delete Profile
    func deleteProfile(profileId: String) async throws {
        do {
            // Use the async version of delete()
            try await db.collection(collectionName).document(profileId).delete()
            LoggerService.shared.log(.info, "✅ Successfully deleted profile for userId: \(profileId)", category: self.category)
        } catch {
            LoggerService.shared.log(.error, "❌ Failed to delete profile: \(error.localizedDescription)", category: self.category)
            throw error
        }
    }

    // MARK: - Fetch Profile
    func fetchProfile(profileId: String) async throws -> Profile {
        do {
            // Use the async version of getDocument()
            let snapshot = try await db.collection(collectionName).document(profileId).getDocument()
            
            guard snapshot.exists else {
                LoggerService.shared.log(.error, "❌ Profile not found for userId: \(profileId)", category: self.category)
                throw NSError(domain: "ProfileService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Profile not found."])
            }
            
            // Decode the Firestore document into a Profile object
            let profile = try snapshot.data(as: Profile.self)
            LoggerService.shared.log(.info, "✅ Successfully fetched profile for userId: \(profileId)", category: self.category)
            return profile
            
        } catch {
            LoggerService.shared.log(.error, "❌ Error fetching or decoding profile: \(error.localizedDescription)", category: self.category)
            throw error
        }
    }
}
