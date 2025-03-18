//
//  MessagesViewModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//

import Foundation
import Combine
import FirebaseDatabase

// MARK: - MessagesViewModel
/// This ViewModel handles fetching, sending, and updating messages in a conversation.
/// It interacts with `MessagesService` to communicate with Firebase.
class MessagesViewModel: ObservableObject {
    
    // MARK: - Published Properties
    /// An array of `MessagesModel` representing messages in a conversation.
    /// This is marked `@Published` so the SwiftUI view automatically updates when new messages arrive.
    @Published var messages: [MessagesModel] = []
    
    // MARK: - Properties
    private let messageService = MessagesService() // The service layer that handles Firebase interactions.
    private var cancellables = Set<AnyCancellable>() // Stores Combine subscriptions to manage memory.
    
    // MARK: - Fetch Messages
    /// Retrieves messages for a given conversation from Firebase.
    /// - Parameter conversationId: The ID of the conversation to fetch messages for.
    func fetchMessages(for conversationId: String) {
        messageService.fetchMessages(for: conversationId) { [weak self] fetchedMessages in
            // Ensure UI updates are made on the main thread since UI changes should not happen on a background thread.
            DispatchQueue.main.async {
                // Sort messages by `sentAt` timestamp to ensure chronological order.
                self?.messages = fetchedMessages.sorted { $0.sentAt < $1.sentAt }
            }
        }
    }
    
    // MARK: - Send Message
    /// Sends a new message to Firebase.
    /// - Parameters:
    ///   - conversationId: The ID of the conversation.
    ///   - senderId: The ID of the user sending the message.
    ///   - text: The message content.
    ///   - type: The message type (default is `"text"`, but could also be `"image"` or `"file"`).
    func sendMessage(conversationId: String, senderId: String, text: String, type: String = "text") {
        messageService.sendMessage(conversationId: conversationId, senderId: senderId, text: text, type: type)
    }
    
    // MARK: - Mark Message as Read
    /// Marks a message as read in Firebase.
    /// - Parameters:
    ///   - conversationId: The ID of the conversation.
    ///   - messageId: The ID of the message to mark as read.
    func markMessageAsRead(conversationId: String, messageId: String) {
        messageService.markMessageAsRead(conversationId: conversationId, messageId: messageId)
    }
    
    // MARK: - Cleanup
    /// Removes the Firebase listener for a specific conversation to stop real-time updates.
    /// This is important for memory management and preventing unnecessary data fetching.
    /// - Parameter conversationId: The ID of the conversation to remove the listener from.
    func removeListener(for conversationId: String) {
        messageService.removeListener(for: conversationId) // Fixed typo from "messagesService"
    }
}
