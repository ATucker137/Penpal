//
//  ConversationsViewModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 2/4/25.
//

import Foundation
import Combine

// TODO: - LOOK MORE INTO THE SEARCH_CONVERSATION AND THE DELETE CONVERSATION LOGIC

// MARK: - ConversationViewModel Definition
// ViewModel responsible for managing conversations data for the user
class ConversationViewModel: ObservableObject {
    
    // MARK: - Properties
    // Published property that will trigger UI updates when conversations change
    @Published var conversations: [ConversationsModel] = []
    
    // Service to interact with the backend or data layer
    private var service = ConversationsService()
    
    // User's unique ID to fetch relevant conversations
    private var userId: String
    private let category = "Conversation ViewModel"


    // MARK: - Initializer
    // Initializer that takes in a userId and immediately fetches conversations
    init(userId: String) {
        self.userId = userId
        LoggerService.shared.log(.debug, "Initializing ConversationViewModel for user: \(userId)", category: category)
        fetchConversations() // Fetching conversations when ViewModel is initialized
    }
    
    // MARK: - Fetch Conversations
    // Fetch user’s conversations from the service
    // This method is called when the ViewModel is initialized and when the conversations list is refreshed
    func fetchConversations() {
        // Calling the service's fetchConversations function
        LoggerService.shared.log(.info, "Fetching conversations for user: \(userId)", category: category)
        service.fetchConversations(for: userId) { [weak self] conversations in
            DispatchQueue.main.async {
                self?.conversations = conversations // Update the conversations list on the main thread
                LoggerService.shared.log(.info, "Updated local conversation list with \(conversations.count) conversations", category: self?.category ?? "Unknown")
            }
        }
    }
    
    // MARK: - Create Conversation
    // Create a new conversation with a specific penpal and an initial message
    func createConversation(penpalId: String, initialMessage: String) {
        LoggerService.shared.log(.info, "Creating conversation with penpal: \(penpalId)", category: category)
        service.createConversation(userId: userId, penpalId: penpalId, initialMessage: initialMessage) { [weak self] conversationId in
            guard let self = self, let conversationId = conversationId else {
                LoggerService.shared.log(.error, "Failed to create conversation (conversationId was nil)", category: self?.category ?? "Unknown")
                return }

            let now = Date()
            let participants = [self.userId, penpalId]

            // 1. Insert into SQLite immediately
            SQLiteManager.shared.insertSingleConversation(
                conversationId: conversationId,
                participants: participants,
                lastMessage: initialMessage,
                lastUpdated: now,
                isSynced: true // Mark as synced since it was just written to Firestore
            )
            LoggerService.shared.log(.info, "Inserted new conversation into local cache (SQLite)", category: self.category)
            // 2. Update conversations list in UI
            self.fetchConversations()
        }
    }

    // MARK: - Delete Conversation

    /// Delete a conversation for the current user only, not affecting the other user's conversation list
    func deleteConversation(conversationId: String, penpalId: String) {
        // Calls the service to remove the conversation from the backend
        LoggerService.shared.log(.info, "Attempting to delete conversation: \(conversationId) for user: \(userId)", category: category)
        service.deleteConversation(userId: userId, conversationId: conversationId, penpalId: penpalId) { [weak self] success in
            guard let self = self else { return }

            if success {
                LoggerService.shared.log(.info, "Successfully deleted conversation: \(conversationId)", category: self.category)
                DispatchQueue.main.async {
                    // Safely update UI only after confirming deletion succeeded
                    self.conversations.removeAll { $0.id == conversationId }
                }
            } else {
                // Optionally handle failure (e.g., show alert, retry)
                LoggerService.shared.log(.error, "Failed to delete conversation: \(conversationId)", category: self.category)
            }
        }
    }

    
    // MARK: - Search Conversations
    // Search for a conversation by a query string (e.g., message text)
    func searchInConversations(query: String) {
        LoggerService.shared.log(.info, "Searching conversations with query: '\(query)'", category: category)
        // 1. Get cached results immediately
        let cachedResults = SQLiteManager.shared.searchConversations(query: query, userId: userId)
        self.conversations = cachedResults
        LoggerService.shared.log(.debug, "Cached search returned \(cachedResults.count) results", category: category)
        // 2. Then fetch latest from Firestore to update cache and UI
        service.fetchConversations(for: userId) { [weak self] latestConversations in
            guard let self = self else { return }

            // Cache the fresh data
            SQLiteManager.shared.cacheConversations(latestConversations)

            // Re-run the search on the updated cache
            let updatedResults = SQLiteManager.shared.searchConversations(query: query, userId: self.userId)
            LoggerService.shared.log(.debug, "Firestore search returned \(latestConversations.count) updated conversations", category: self.category)
            DispatchQueue.main.async {
                self.conversations = updatedResults
                LoggerService.shared.log(.info, "UI updated with \(updatedResults.count) search results", category: self.category)
            }
        }
    }
    
    func updateConversationLastMessage(conversationId: String, message: String) {
        LoggerService.shared.log(.info, "Updating last message in conversation: \(conversationId)", category: category)
        let now = Date()

        // Update Firestore
        service.updateConversationLastMessage(conversationId: conversationId, message: message, lastUpdated: now)

        // Update local SQLite for offline cache
        SQLiteManager.shared.updateLastMessage(conversationId: conversationId, message: message, lastUpdated: now)
        LoggerService.shared.log(.debug, "Updated last message locally for conversation: \(conversationId)", category: category)

    }


    //TODO: - Create Did Select Conversation
    
    // MARK: - Deinitializer
    // Deinitializer to remove listeners when ViewModel is deallocated
    // This prevents memory leaks from the listener in the service layer
    deinit {
        service.removeListener() // Removes any active listeners or observers
        LoggerService.shared.log(.debug, "ConversationViewModel deinitialized and listener removed", category: category)

    }
}
