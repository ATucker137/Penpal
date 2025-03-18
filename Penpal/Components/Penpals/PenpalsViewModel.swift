//
//  PenpalsViewModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//

import Foundation
import FirebaseFirestore

/// ViewModel responsible for managing potential penpal matches.
class PenpalViewModel: ObservableObject {
    @Published var potentialMatches: [PenpalsModel] = [] // Stores fetched penpals
    private let penpalService = PenpalService() // Service layer for handling Firestore operations
    private var userId: String? {
        return UserSession.shared.userId
    }
    
    /// Starts listening for profile changes and fetches potential matches.
    func startListeningForMatches() {
        penpalService.listenForProfileChanges(userId: userId)
    }
    
    /// Fetches potential matches from Firestore and updates the UI.
    func fetchMatches() {
        let db = Firestore.firestore()
        
        db.collection("potentialMatches")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents, error == nil else { return }
                
                var matches: [PenpalsModel] = []
                
                for doc in documents {
                    let data = doc.data()
                    
                    if let penpalId = data["penpalId"] as? String,
                       let firstName = data["firstName"] as? String,
                       let lastName = data["lastName"] as? String,
                       let proficiency = data["proficiency"] as? String,
                       let hobbies = data["hobbies"] as? [String],
                       let goals = data["goals"] as? String,
                       let region = data["region"] as? String,
                       let matchScore = data["matchScore"] as? Int,
                       let statusRaw = data["status"] as? String,
                       let status = MatchStatus(rawValue: statusRaw) {
                        
                        let penpal = PenpalsModel(
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
                        
                        matches.append(penpal)
                    }
                }
                
                DispatchQueue.main.async {
                    self.potentialMatches = matches
                }
            }
    }
    
    /// Updates the match status (Approved, Pending, Declined) for a given penpal.
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
    
    // MARK: - Other Functions possibly needed
    
    // TODO: - Send Request
    // TODO: - Notify The User Penpal On People that want user to be their penpal
    // TODO: - Decline request
    // TODO: - Accept request
    // TODO: - Update the things user is looking for
    
    
    
}

/// Enum representing the different match statuses.
enum MatchStatus: String, Codable {
    case pending = "pending"
    case approved = "approved"
    case declined = "declined"
}

