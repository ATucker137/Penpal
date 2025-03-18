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
// TODO: - Chatgpt Complains about the  whereField
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
            .whereField("userId", isEqualTo: userId) // Filters conversations where user is a participant (potential issue: should use arrayContains for multiple participants)
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
            userId: userId,
            penpalId: penpalId,
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
    
    // MARK: - Deletes a conversation between two users
    func deleteConversation(userId: String, conversationId: String, penpalId: String) {
        let db = Firestore.firestore()
        
        // Reference to the conversation document
        let conversationRef = db.collection("conversations").document(conversationId)
        let userRef = db.collection("users").document(userId)
        let penpalRef = db.collection("users").document(penpalId)
        
        // Start a Firestore transaction to ensure consistency
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            // Fetch the conversation document
            guard let conversationSnapshot = try? transaction.getDocument(conversationRef),
                  let conversationData = conversationSnapshot.data(),
                  let currentUserId = conversationData["userId"] as? String,
                  let currentPenpalId = conversationData["penpalId"] as? String
            else {
                print("Conversation data not found or malformed.")
                return nil
            }
            
            // Ensure the user requesting deletion is a participant
            if currentUserId != userId && currentPenpalId != userId {
                print("User not authorized to delete this conversation.")
                return nil
            }
            
            // Remove conversation ID from both users' documents
            transaction.updateData([
                "conversations": FieldValue.arrayRemove([conversationId])
            ], forDocument: userRef)
            
            transaction.updateData([
                "conversations": FieldValue.arrayRemove([conversationId])
            ], forDocument: penpalRef)
            
            // If both users have removed the conversation, delete the conversation document
            if currentUserId == userId || currentPenpalId == userId {
                transaction.deleteDocument(conversationRef)
                print("Conversation deleted from Firestore.")
            }
            
            return nil
        }, completion: { (object, error) in
            if let error = error {
                print("Error deleting conversation: \(error.localizedDescription)")
            } else {
                print("Conversation deletion process completed.")
            }
        })
    }
}
