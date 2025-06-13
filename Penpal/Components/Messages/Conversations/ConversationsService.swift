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
                    print("Error fetching conversations: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                // Maps Firestore documents to ConversationsModel objects
                let conversations = documents.compactMap { doc -> ConversationsModel? in
                    try? doc.data(as: ConversationsModel.self)
                }
                completion(conversations) // Returns fetched conversations
            }
    }
    
    // MARK: - Stops listening to Firestore updates when no longer needed
    func removeListener() {
        listener?.remove() // Removes Firestore listener
        listener = nil // Ensures it's properly deallocated
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
            print("Error encoding conversation: \(error.localizedDescription)")
            completion(nil)
            return
        }
        
        // Update the users' documents to include the conversation ID
        batch.updateData(["conversations": FieldValue.arrayUnion([conversationId])], forDocument: userRef)
        batch.updateData(["conversations": FieldValue.arrayUnion([conversationId])], forDocument: penpalRef)
        
        // Commit batch write to Firestore
        batch.commit { error in
            if let error = error {
                print("Error creating conversation: \(error.localizedDescription)")
                completion(nil)
            } else {
                print("Conversation successfully created.")
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
                print("Error updating conversation last message: \(error.localizedDescription)")
            } else {
                print("Successfully updated conversation last message.")
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
                print("Conversation data missing or malformed.")
                return nil
            }

            // Ensure the current user is part of the conversation
            guard participants.contains(userId) else {
                print("User not a participant in this conversation.")
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
            }

            return nil
        }, completion: { (_, error) in
            if let error = error {
                print("Failed to delete conversation: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Conversation deletion handled successfully.")
                completion(true)
            }
        })
    }

}
