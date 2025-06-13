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
                self.syncAndFetchMatches(userId: userId) { result in
                    switch result {
                    case .success(let matches):
                        // Optionally, update the UI with the new matches, if needed
                        print("Successfully fetched and synced matches for user: \(userId).")
                    case .failure(let error):
                        print("Error fetching matches: \(error)")
                    }
                }
            }
        }
    }
    
    /// Queries Firestore to fetch penpal matches based on dynamic criteria such as shared interests, goals, and proficiency levels.
    /// This function performs a **live query** to find users who meet certain conditions, like similar hobbies, proficiency levels, goals, or other factors.
    ///
    /// **Purpose**: This function is designed to perform a **real-time search** of potential penpal matches for a given user based on the current, dynamic data (i.e., interests, goals, proficiency) of the user and potential penpals.
    ///
    /// **When to Use**: Use this when you want to dynamically **fetch and match** users who meet specific criteria at the time of the query. The query may use parameters such as hobbies, proficiency level, and other factors to find penpals who meet the current user's needs.
    ///
    /// **Example Scenario**: A user wants to find penpals who share similar hobbies like "traveling" and "reading" and are at the same proficiency level. The app dynamically fetches these potential matches by querying Firestore using those parameters.
        
    // MARK: - Fetch Matches Based on Criteria
    func fetchMatchesForUser(userId: String, interests: [String], goals: String, proficiencyLevel: String, completion: @escaping (Result<[PenpalsModel], Error>) -> Void) {
        let db = Firestore.firestore()

        db.collection("users")
            .whereField("hobbies", arrayContainsAny: interests) // Filter by hobbies
            .whereField("goals", isEqualTo: goals) // Filter by goals
            .whereField("proficiency", isEqualTo: proficiencyLevel) // Filter by proficiency level
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }

                let matches: [PenpalsModel] = documents.compactMap { doc in
                    let data = doc.data()

                    guard let penpalId = data["userId"] as? String,
                          let firstName = data["firstName"] as? String,
                          let lastName = data["lastName"] as? String,
                          let proficiency = data["proficiency"] as? String,
                          let hobbies = data["hobbies"] as? [String],
                          let goals = data["goals"] as? String,
                          let region = data["region"] as? String
                    else {
                        return nil
                    }

                    return PenpalsModel(
                        userId: userId,
                        penpalId: penpalId,
                        firstName: firstName,
                        lastName: lastName,
                        proficiency: proficiency,
                        hobbies: hobbies,
                        goals: goals,
                        region: region
                    )
                }

                completion(.success(matches))
            }
    }

    
    
    /// Fetches potential penpal matches based on shared interests.
    /// This function queries Firestore to find users with similar hobbies, goals, and proficiency levels.
    ///
    /// **Purpose**: This function fetches **pre-calculated matches** that have already been assigned or stored in the
    /// `potentialMatches` collection. It retrieves matches that the app has already identified and scored in advance,
    /// based on shared interests or other criteria.
    ///
    /// **When to Use**: Use this when you want to fetch **pre-determined matches** for a user that may already be stored.
    /// This could be based on an earlier matching process or when a set of matches has been curated and stored in Firestore,
    /// ready to be retrieved quickly without re-running the query logic.
    ///
    /// **Example Scenario**: A user has already been matched with several other users based on shared interests or goals.
    /// Now, you want to fetch and display these pre-filtered matches stored in your app's database.
        
    // MARK: - Fetch Matches
    func fetchPotentialMatchesFromFirestore(for userId: String, completion: @escaping (Result<[PenpalsModel], Error>) -> Void) {
        let db = Firestore.firestore()

        db.collection("potentialMatches")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }

                let matches: [PenpalsModel] = documents.compactMap { doc in
                    let data = doc.data()
                    
                    guard let penpalId = data["penpalId"] as? String,
                          let firstName = data["firstName"] as? String,
                          let lastName = data["lastName"] as? String,
                          let proficiency = data["proficiency"] as? String,
                          let hobbies = data["hobbies"] as? [String],
                          let goals = data["goals"] as? String,
                          let region = data["region"] as? String,
                          let matchScore = data["matchScore"] as? Int,
                          let statusRaw = data["status"] as? String,
                          let status = MatchStatus(rawValue: statusRaw)
                    else {
                        return nil
                    }
                    
                    return PenpalsModel(
                        userId: userId,
                        penpalId: penpalId,
                        firstName: firstName,
                        lastName: lastName,
                        proficiency: proficiency,
                        hobbies: hobbies,
                        goals: goals,
                        region: region,
                        matchScore: matchScore,
                        status: status
                    )
                }

                completion(.success(matches))
            }
    }

    
    // MARK: - Sync And Fetch Matches
    func syncAndFetchMatches(userId: String, completion: @escaping (Result<[PenpalsModel], Error>) -> Void) {
        fetchPotentialMatchesFromFirestore(for: userId) { [weak self] result in
            switch result {
            case .success(let matches):
                self?.sqliteManager.cachePenpals(matches)
                completion(.success(matches))
            case .failure:
                print("Fetching from Firestore failed — falling back to SQLite.")
                let cached = self?.sqliteManager.getCachedPenpals(for: userId) ?? []
                completion(.success(cached))
            }
        }
    }

    
    /// Updates the match status (Approved, Pending, Declined) for a given penpal.
    // MARK: - Update Match Status
    func updateMatchStatus(penpalId: String, newStatus: MatchStatus) {
        let db = Firestore.firestore()
        let matchRef = db.collection("potentialMatches").document("\(userId)_\(penpalId)")
        
        matchRef.updateData(["status": newStatus.rawValue]) { error in
            if let error = error {
                print("Error updating match status: \(error)")
            } else {
                DispatchQueue.main.async {
                    if let index = self.potentialMatches.firstIndex(where: { $0.penpalId == penpalId }) {
                        self.potentialMatches[index].status = newStatus
                    }
                }
            }
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
    
    // Update match status
    func updateMatchStatus(penpalId: String, newStatus: MatchStatus, userId: String, completion: @escaping (Bool) -> Void) {
        let matchRef = db.collection("potentialMatches").document("\(userId)_\(penpalId)")
        
        matchRef.updateData(["status": newStatus.rawValue]) { error in
            if let error = error {
                print("Error updating match status: \(error)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    // Send friend request
    func sendFriendRequest(to penpalId: String, userId: String, completion: @escaping (Bool) -> Void) {
        let matchRef = db.collection("potentialMatches").document("\(userId)_\(penpalId)")
        
        matchRef.setData(["status": MatchStatus.pending.rawValue]) { error in
            if let error = error {
                print("Error sending friend request: \(error)")
                completion(false)
            } else {
                print("Friend request sent successfully.")
                completion(true)
            }
        }
    }

    // Decline friend request
    func declineFriendRequest(from penpalId: String, userId: String, completion: @escaping (Bool) -> Void) {
        let matchRef = db.collection("potentialMatches").document("\(userId)_\(penpalId)")
        
        matchRef.updateData(["status": MatchStatus.declined.rawValue]) { error in
            if let error = error {
                print("Error declining friend request: \(error)")
                completion(false)
            } else {
                print("Friend request declined successfully.")
                completion(true)
            }
        }
    }

    // Accept friend request
    func acceptFriendRequest(from penpalId: String, userId: String, completion: @escaping (Bool) -> Void) {
        let matchRef = db.collection("potentialMatches").document("\(userId)_\(penpalId)")
        
        matchRef.updateData(["status": MatchStatus.approved.rawValue]) { error in
            if let error = error {
                print("Error accepting friend request: \(error)")
                completion(false)
            } else {
                print("Friend request accepted.")
                // Sync penpal data here (if necessary)
                completion(true)
            }
        }
    }
    
    // MARK: - Enforce Penpal Limit
    
    // MARK: - Sync Penpal
    func syncPenpal(with penpalId: String) {
        let userPenpalRef = db.collection("users").document(userId ?? "").collection("penpals").document(penpalId)
        
        userPenpalRef.setData(["status": "active", "updatedAt": Timestamp(date: Date())]) { error in
            if let error = error {
                print("Error syncing penpal: \(error)")
            } else {
                print("Penpal synced successfully.")
            }
        }
    }
    
    // MARK: -  Delete Penpals
    func deletePenpal(penpalId: String, for userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let penpalRef = db
            .collection("users")
            .document(userId)
            .collection("penpals")
            .document(penpalId)

        penpalRef.delete { error in
            if let error = error {
                print("Failed to delete penpal: \(error)")
                completion(.failure(error))
            } else {
                print("Successfully deleted penpal: \(penpalId)")
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Cache Penpals Also Goes Here?
    
    // MARK: - Count Cached Penpals
    
    // MARK: - Fetch Cached Penpals
    
    
    // TODO: - Update the things user is looking for

    // TODO: - Notify The User Penpal On People that want user to be their penpal
}

