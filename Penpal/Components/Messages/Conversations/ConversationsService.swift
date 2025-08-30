//
//  ConversationsService.swift
//  Penpal
//
//  Created by Austin William Tucker on 2/4/25.
//

import Foundation
import Firestore
import FirebaseFirestore
import FirebaseFirestoreSwift
import Combine

// Service responsible for handling conversation-related Firestore operations
// TODO: - Change The Delete Conversation So Only the User thats deleting it will delete it on their end but not the penpal id
class ConversationsService {
    
    private let db = Firestore.firestore() // Reference to Firestore database
    private var listener: ListenerRegistration? // Listener for real-time updates on conversations
    private let category = "Conversation Service"
    
    deinit {
        removeListener() // Ensure listener is removed when instance is deallocated
    }
    
    // MARK: - Fetches conversations for a specific user and listens for real-time updates
    func fetchConversations(for userId: String, completion: @escaping([ConversationsModel]) -> Void) {
        removeListener() // Remove any existing listener to prevent duplicates
        
        listener = db.collection("conversations")
            .whereField("participants", arrayContains: userId)
            .order(by: "lastUpdated", descending: true) // Orders conversations by most recent activity
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    LoggerService.shared.log(.error, "Error fetching conversations: \(error?.localizedDescription ?? "Unknown error")", category: self.category)
                    return
                }
                
                // Maps Firestore documents to ConversationsModel objects
                let conversations = documents.compactMap { doc -> ConversationsModel? in
                    try? doc.data(as: ConversationsModel.self)
                }
                LoggerService.shared.log(.info, "Fetched \(conversations.count) conversations for user \(userId)", category: self.category)
                completion(conversations) // Returns fetched conversations
            }
    }
    
    // MARK: - Stops listening to Firestore updates when no longer needed
    func removeListener() {
        listener?.remove() // Removes Firestore listener
        listener = nil // Ensures it's properly deallocated
        LoggerService.shared.log(.debug, "Firestore listener removed", category: category)
    }
    
    // MARK: - Placeholder function for searching within conversations
    func searchInConversations() {}
    
    // MARK: - Creates a new conversation between two users
    
    func createConversation(userId: String, penpalId: String, initialMessage: String, completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()
        let batch = db.batch() // Firestore batch write for atomic operations
        
        let conversationId = UUID().uuidString // Generate a unique ID for the conversation
        let conversationRef = db.collection("conversations").document(conversationId) // Reference to new conversation document
        let userRef = db.collection("users").document(userId) // Reference to user document
        let penpalRef = db.collection("users").document(penpalId) // Reference to penpal document
        
        // Create a new conversation model
        let newConversation = ConversationsModel(
            id: conversationId,
            participants: [userId, penpalId],
            lastMessage: initialMessage,
            lastUpdated: Date()
        )
        
        do {
            try batch.setData(from: newConversation, forDocument: conversationRef) // Save conversation document
        } catch {
            LoggerService.shared.log(.error, "Error encoding conversation: \(error.localizedDescription)", category: category)
            completion(nil)
            return
        }
        
        // Update the users' documents to include the conversation ID
        batch.updateData(["conversations": FieldValue.arrayUnion([conversationId])], forDocument: userRef)
        batch.updateData(["conversations": FieldValue.arrayUnion([conversationId])], forDocument: penpalRef)
        
        // Commit batch write to Firestore
        batch.commit { error in
            if let error = error {
                LoggerService.shared.log(.error, "Error creating conversation: \(error.localizedDescription)", category: self.category)
                completion(nil)
            } else {
                LoggerService.shared.log(.info, "Successfully created conversation \(conversationId)", category: self.category)
                completion(conversationId)
            }
        }
    }
    
    // MARK: - Update Conversation Last Message
    func updateConversationLastMessage(conversationId: String, message: String, lastUpdated: Date) {
        let db = Firestore.firestore()
        let ref = db.collection("conversations").document(conversationId)

        ref.updateData([
            "lastMessage": message,
            "lastUpdated": Timestamp(date: lastUpdated)
        ]) { error in
            if let error = error {
                LoggerService.shared.log(.error, "Error updating conversation \(conversationId): \(error.localizedDescription)", category: self.category)
            } else {
                LoggerService.shared.log(.info, "Updated lastMessage for conversation \(conversationId)", category: self.category)
            }
        }
    }

    // MARK: - Delete Conversation
    func deleteConversation(userId: String, conversationId: String, penpalId: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()

        let conversationRef = db.collection("conversations").document(conversationId)
        let userRef = db.collection("users").document(userId)

        db.runTransaction({ (transaction, errorPointer) -> Any? in
            guard let conversationSnapshot = try? transaction.getDocument(conversationRef),
                  let data = conversationSnapshot.data(),
                  let participants = data["participants"] as? [String]
            else {
                LoggerService.shared.log(.error, "Conversation data missing or malformed.", category: self.category)
                return nil
            }

            // Ensure the current user is part of the conversation
            guard participants.contains(userId) else {
                LoggerService.shared.log(.error, "User \(userId) not a participant in conversation \(conversationId).", category: self.category)
                return nil
            }

            // Mark the conversation as deleted for the current user
            let deletedFor = data["deletedFor"] as? [String] ?? []
            if !deletedFor.contains(userId) {
                var updatedDeletedFor = deletedFor
                updatedDeletedFor.append(userId)
                transaction.updateData(["deletedFor": updatedDeletedFor], forDocument: conversationRef)
            }

            // Remove from user's "conversations" list (if you store it)
            transaction.updateData([
                "conversations": FieldValue.arrayRemove([conversationId])
            ], forDocument: userRef)

            // If both users have deleted the conversation, delete it entirely
            if Set(updatedDeletedFor).isSuperset(of: Set(participants)) {
                transaction.deleteDocument(conversationRef)
                LoggerService.shared.log(.info, "Both users deleted conversation \(conversationId); deleting from Firestore.", category: self.category)

            } else {
                LoggerService.shared.log(.info, "Marked conversation \(conversationId) as deleted for user \(userId).", category: self.category)
            }

            return nil
        }, completion: { (_, error) in
            if let error = error {
                LoggerService.shared.log(.error, "Failed to delete conversation: \(error.localizedDescription)", category: self.category)
                completion(false)
            } else {
                LoggerService.shared.log(.info, "Successfully handled deletion for conversation \(conversationId)", category: self.category)
                completion(true)
            }
        })
    }

}
