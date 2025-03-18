//
//  PenpalsService.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//
import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift


import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Service responsible for fetching and updating potential penpal matches.
class PenpalsService {
    private let db = Firestore.firestore() // Reference to Firestore database
    private var profileListener: ListenerRegistration? // Listener for tracking user profile changes
    
    /// Starts listening for changes in the user's profile.
    /// If the user updates hobbies, goals, or proficiency, fetch new potential matches.
    // MARK: - Listen For Profile Changes
    func listenForProfileChanges(userId: String) {
        profileListener = db.collection("users").document(userId).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self, let data = snapshot?.data(), error == nil else { return }
            
            // Extract user details from Firestore document
            if let hobbies = data["hobbies"] as? [String],
               let goals = data["goals"] as? String,
               let proficiency = data["proficiency"] as? String {
                
                print("Profile updated! Fetching new matches...")
                
                // Fetch and update potential matches whenever the user's profile changes
                self.fetchAndUpdatePotentialMatches(userId: userId, hobbies: hobbies, goals: goals, proficiency: proficiency)
            }
        }
    }
    
    /// Fetches potential penpal matches based on shared interests.
    /// This function queries Firestore to find users with similar hobbies, goals, and proficiency levels.
    // MARK: - Fetch And Update Potential Matches
    private func fetchAndUpdatePotentialMatches(userId: String, hobbies: [String], goals: String, proficiency: String) {
        db.collection("users")
            .whereField("userId", isNotEqualTo: userId) // Exclude the current user from results
            .getDocuments { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents, error == nil else { return }
                
                var potentialMatches: [PenpalsModel] = [] // Array to store potential matches
                
                for doc in documents {
                    let data = doc.data()
                    
                    // Extract potential match details
                    if let penpalId = data["userId"] as? String,
                       let penpalHobbies = data["hobbies"] as? [String],
                       let penpalGoals = data["goals"] as? String,
                       let penpalProficiency = data["proficiency"] as? String {
                        
                        // Calculate a match score based on shared interests
                        let matchScore = self.calculateMatchScore(userHobbies: hobbies, penpalHobbies: penpalHobbies)
                        
                        // Create a PenpalsModel instance for this match
                        let penpal = PenpalsModel(
                            userId: userId,
                            penpalId: penpalId,
                            firstName: data["firstName"] as? String ?? "",
                            lastName: data["lastName"] as? String ?? "",
                            proficiency: penpalProficiency,
                            hobbies: penpalHobbies,
                            goals: penpalGoals,
                            region: data["region"] as? String ?? "",
                            matchScore: matchScore,
                            status: .pending // Default status when a match is first found
                        )
                        
                        potentialMatches.append(penpal)
                    }
                }
                
                // Store the potential matches in Firestore in a batch write
                self.updatePotentialMatches(userId: userId, matches: potentialMatches)
            }
    }
    
    /// Calculates a match score based on the number of shared hobbies between users.
    /// - Returns: An integer representing the match quality (higher score = better match).
    // MARK: - Calculate Matcher Score of A User
    // TODO: - Also Needs To Add Goals, Time Preference, Language Target maybe region
    private func calculateMatchScore(userHobbies: [String], penpalHobbies: [String]) -> Int {
        let commonInterests = Set(userHobbies).intersection(Set(penpalHobbies)) // Find shared hobbies
        return commonInterests.count * 10 // Assign 10 points per shared hobby
    }
    
    /// Updates potential matches in Firestore using batch writes for efficiency.
    /// This ensures all matches are updated at once, reducing database writes.
    // MARK: - UPdate Potential Matches
    private func updatePotentialMatches(userId: String, matches: [PenpalsModel]) {
        let batch = db.batch()
        let matchesRef = db.collection("potentialMatches")

        for match in matches {
            let matchRef = matchesRef.document("\(userId)_\(match.penpalId)") // Unique document ID per match
            
            // Store match details in Firestore
            batch.setData([
                "userId": match.userId,
                "penpalId": match.penpalId,
                "firstName": match.firstName,
                "lastName": match.lastName,
                "proficiency": match.proficiency,
                "hobbies": match.hobbies,
                "goals": match.goals,
                "region": match.region,
                "matchScore": match.matchScore,
                "status": match.status.rawValue // Convert enum to string for storage
            ], forDocument: matchRef)
        }

        // Commit all updates in a single batch operation
        batch.commit { error in
            if let error = error {
                print("Error updating matches: \(error)")
            } else {
                print("Potential matches updated successfully.")
            }
        }
    }
}

