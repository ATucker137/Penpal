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


class ProfileService {
    private let db = Firestore.firestore()
    private let collectionName = "profiles"

    // MARK: - Create Profile
    func createProfile(profile: Profile, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try db.collection(collectionName).document(profile.id).setData(from: profile) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch let error {
            completion(.failure(error))
        }
    }

    // MARK: - Update Profile
    func updateProfile(profile: Profile, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try db.collection(collectionName).document(profile.id).setData(from: profile, merge: true) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch let error {
            completion(.failure(error))
        }
    }

    // MARK: - Delete Profile
    func deleteProfile(profileId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection(collectionName).document(profileId).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    // MARK: - Fetch Profile
    func fetchProfile(profileId: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        db.collection(collectionName).document(profileId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let snapshot = snapshot, snapshot.exists else {
                completion(.failure(NSError(domain: "ProfileService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Profile not found."])))
                return
            }

            do {
                let profile = try snapshot.data(as: Profile.self) // Decode Firestore document into Profile
                completion(.success(profile))
            } catch let error {
                completion(.failure(error))
            }
        }
    }
}
