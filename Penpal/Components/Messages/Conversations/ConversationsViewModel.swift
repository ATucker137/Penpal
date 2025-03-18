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

    // MARK: - Initializer
    // Initializer that takes in a userId and immediately fetches conversations
    init(userId: String) {
        self.userId = userId
        fetchConversations() // Fetching conversations when ViewModel is initialized
    }
    
    // MARK: - Fetch Conversations
    // Fetch user’s conversations from the service
    // This method is called when the ViewModel is initialized and when the conversations list is refreshed
    func fetchConversations() {
        // Calling the service's fetchConversations function
        service.fetchConversations(for: userId) { [weak self] conversations in
            DispatchQueue.main.async {
                self?.conversations = conversations // Update the conversations list on the main thread
            }
        }
    }
    
    // MARK: - Create Conversation
    // Create a new conversation with a specific penpal and an initial message
    func createConversation(penpalId: String, initialMessage: String) {
        // Calls the service to create the conversation and pass back the conversationId if successful
        service.createConversation(userId: userId, penpalId: penpalId, initialMessage: initialMessage) { [weak self] conversationId in
            guard let conversationId = conversationId else { return }
            
            // Refresh the conversations list after the new conversation is created
            self?.fetchConversations()
        }
    }
    
    // MARK: - Delete Conversation
    
    // Delete a conversation for the current user only, not affecting the other user's conversation list
    func deleteConversation(conversationId: String, penpalId: String) {
        // Calls the service to remove the conversation from the backend
        service.deleteConversation(userId: userId, conversationId: conversationId, penpalId: penpalId)
        
        // Removes the conversation locally for UI update
        // This removes any conversations that have the given `conversationId`
        self.conversations.removeAll { $0.id == conversationId }
    }
    
    // MARK: - Search Conversations
    // Search for a conversation by a query string (e.g., message text)
    func searchInConversations(query: String) {
        // Filters the conversations by checking if the `lastMessage` contains the search query
        let filtered = conversations.filter { $0.lastMessage?.localizedCaseInsensitiveContains(query) ?? false }
        
        // Updates the `conversations` array with the filtered results
        // The use of the `?? false` ensures that the search doesn't break if `lastMessage` is nil
        self.conversations = filtered
    }
    
    // MARK: - Deinitializer
    // Deinitializer to remove listeners when ViewModel is deallocated
    // This prevents memory leaks from the listener in the service layer
    deinit {
        service.removeListener() // Removes any active listeners or observers
    }
}
