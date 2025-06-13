//
//  PenpalsViewModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//

import Foundation
import FirebaseFirestore




/// ViewModel responsible for managing potential penpal matches.
class PenpalsViewModel: ObservableObject {
    @Published var potentialMatches: [PenpalsModel] = []
    @Published var matchStatus: MatchStatus? // The current match status of a penpal
    @Published var syncErrorMessage: String? // Holds the error message in case syncing fails
    @Published var syncSuccessMessage: String? // Holds a success message
    
    // Stores fetched penpals
    private let penpalService = PenpalsService() // Service layer for handling Firestore operations
    private var userId: String? {
        return UserSession.shared.userId
    }
    
    /// Starts listening for profile changes and fetches potential matches.
    func startListeningForMatches() {
        penpalService.listenForProfileChanges(userId: userId)
    }
    
    // MARK: - Fetch Matches
    func syncAndFetchMatches(userId: String, completion: @escaping (Result<[PenpalsModel], Error>) -> Void) {
        penpalService.fetchPotentialMatchesFromFirestore(for: userId) { [weak self] result in
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

    
    
    // MARK: - Update Match Status
    func updateMatchStatus(penpalId: String, newStatus: MatchStatus, userId: String) {
        isLoading = true
        penpalService.updateMatchStatus(penpalId: penpalId, newStatus: newStatus, userId: userId) { success in
            DispatchQueue.main.async {
                self.isLoading = false
                if success {
                    self.matchStatus = newStatus // Update the UI with the new status
                } else {
                    self.errorMessage = "Failed to update match status."
                }
            }
        }
    }
    
    // MARK: - Send Friend Request
    func sendFriendRequest(to penpalId: String, userId: String) {
        isLoading = true
        penpalService.sendFriendRequest(to: penpalId, userId: userId) { success in
            DispatchQueue.main.async {
                self.isLoading = false
                if success {
                    self.errorMessage = nil // Clear previous errors
                } else {
                    self.errorMessage = "Failed to send friend request."
                }
            }
        }
    }
    
    // MARK: - Decline Friend Request
    func declineFriendRequest(from penpalId: String, userId: String) {
        isLoading = true
        penpalService.declineFriendRequest(from: penpalId, userId: userId) { success in
            DispatchQueue.main.async {
                self.isLoading = false
                if success {
                    self.errorMessage = nil
                } else {
                    self.errorMessage = "Failed to decline friend request."
                }
            }
        }
    }
    
    // MARK: - Accept Friend Request
    func acceptFriendRequest(from penpalId: String, userId: String) {
        isLoading = true
        penpalService.acceptFriendRequest(from: penpalId, userId: userId) { success in
            DispatchQueue.main.async {
                self.isLoading = false
                if success {
                    self.errorMessage = nil
                    // Optionally, sync penpal data here
                } else {
                    self.errorMessage = "Failed to accept friend request."
                }
            }
        }
    }
    
    // MARK: - Sync Penpal
    /// Synchronizes penpal data for consistency.
    func syncPenpal(with penpalId: String) {
        isLoading = true
        penpalService.syncPenpal(with: penpalId) { success, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if success {
                    self.syncSuccessMessage = "Penpal synced successfully."
                    self.syncErrorMessage = nil
                } else {
                    self.syncErrorMessage = error ?? "Error syncing penpal."
                    self.syncSuccessMessage = nil
                }
            }
        }
    }
    
    // MARK: - Enforce Penpal Limit
    /// Enforces the penpal limit by removing extra requests.
    func enforcePenpalLimit(maxAllowed: Int) {
        if potentialMatches.count > maxAllowed {
            let excess = potentialMatches.count - maxAllowed
            let extraPenpals = potentialMatches.sorted { $0.matchScore < $1.matchScore }.prefix(excess)
            
            for penpal in extraPenpals {
                declineFriendRequest(from: penpal.penpalId)
            }
        }
    }
    
    // MARK: -  Delete Penpals
    func deletePenpal(penpalId: String, for userId: String) {
        penpalService.deletePenpal(penpalId: penpalId, for: userId) { [weak self] result in
            switch result {
            case .success():
                DispatchQueue.main.async {
                    self?.acceptedPenpals.removeAll { $0.penpalId == penpalId }
                }
            case .failure(let error):
                print("Error deleting penpal: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Cache Penpals Also Goes Here?
    
    // MARK: - Count Cached Penpals
    
    // MARK: - Fetch Cached Penpals
    
    // MARK: - Clear Old Penpals
    
    // TODO: - Update the things user is looking for

    // TODO: - Notify The User Penpal On People that want user to be their penpal
    
    
}

/// Enum representing the different match statuses.
enum MatchStatus: String, Codable {
    case pending = "pending"
    case approved = "approved"
    case declined = "declined"
}

