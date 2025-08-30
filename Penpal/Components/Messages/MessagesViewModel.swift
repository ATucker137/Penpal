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
    @Published var hasMoreMessages: Bool = true
    @Published var oldestMessageTimestamp: TimeInterval? = nil
    @Published var isLoadingMessages = false // to disable UI interaction during fetches
    
    // MARK: - Properties
    private let messageService = MessagesService() // The service layer that handles Firebase interactions.
    private let sqliteManager = SQLiteManager()
    private var cancellables = Set<AnyCancellable>() // Stores Combine subscriptions to manage memory.
    private let category = "Message ViewModel"

    init(conversationId: String) {
        self.conversationId = conversationId
    }

    
    // MARK: - Fetch Messages
    /// Retrieves messages for a given conversation from Firebase and syncs with local SQLite.
   
    func fetchMessages() {
        guard let conversationId = self.conversationId else {
            LoggerService.shared.log(.error, "conversationId is not set.", category: category)
                return
            }
        let cachedMessages = self.sqliteManager.fetchMessagesForConversation(conversationId: conversationId)
        let sortedCached = cachedMessages.sorted { $0.sentAt < $1.sentAt }
        self.messages = sortedCached
        self.oldestMessageTimestamp = sortedCached.first?.sentAt
        LoggerService.shared.log(.info, "Fetching messages from Firebase for conversation: \(conversationId)", category: category)
        messageService.fetchMessages(for: conversationId) { [weak self] fetchedMessages in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if fetchedMessages.isEmpty {
                    //  No Firebase messages → fall back to SQLite
                    LoggerService.shared.log(.info, "No messages fetched from Firebase, falling back to SQLite.", category: category)
                    let localMessages = self.sqliteManager.fetchMessagesForConversation(conversationId: conversationId)
                    let sorted = localMessages.sorted { $0.sentAt < $1.sentAt }
                    self.messages = sorted
                    self.oldestMessageTimestamp = sorted.first?.sentAt
                    self.hasMoreMessages = false // Assume local storage is finite
                } else {
                    LoggerService.shared.log(.info, "Fetched \(fetchedMessages.count) messages from Firebase.", category: category)
                    // ✅ Deduplicate against current in-memory list (optional if replacing)
                    let deduped = self.deduplicate(fetchedMessages)

                    //  Sort messages chronologically
                    let sorted = deduped.sorted { $0.sentAt < $1.sentAt }

                    //  Sync Firebase-fetched messages to SQLite
                    self.sqliteManager.insertOrUpdateMessages(sorted)

                    // 🪄 Update local state
                    self.messages = sorted
                    self.oldestMessageTimestamp = sorted.first?.sentAt
                    self.hasMoreMessages = sorted.count >= 20
                }
            }
        }
    }

    
    // Helper to filter out messages that already exist in the current list
    private func deduplicate(_ newMessages: [MessagesModel]) -> [MessagesModel] {
        let existingIds = Set(self.messages.map { $0.id })
        let filteredMessages = newMessages.filter { !existingIds.contains($0.id) }
            
            LoggerService.shared.log(.info, "Deduplicating messages: \(newMessages.count) incoming, \(filteredMessages.count) after filtering duplicates.", category: category)
            
            return filteredMessages
    }



    
    // MARK: - Send Message
    /// Sends a new message to Firebase and updates message status accordingly.
    /// - Parameters:
    ///   - senderId: The ID of the user sending the message.
    ///   - text: The message content.
    ///   - type: The message type (default is "text").
    func sendMessage(senderId: String, text: String, type: String = "text") {
        guard let conversationId = self.conversationId else {
            LoggerService.shared.log(.error, "sendMessage failed: conversationId is not set.", category: category)
                return
            }
        // 1. Create a local "pending" message to immediately show in the UI
        let messageId = UUID().uuidString
        let tempMessage = MessagesModel(
            id: messageId,
            conversationId: conversationId,
            senderId: senderId,
            text: text,
            type: type,
            sentAt: Date().timeIntervalSince1970,
            status: .pending
        )

        messages.append(tempMessage)
        LoggerService.shared.log(.info, "Created pending message with ID \(messageId) for conversation \(conversationId).", category: category)
        // ✅ Insert into local cache immediately
        sqliteManager.insertMessage(tempMessage)
        LoggerService.shared.log(.debug, "Inserted pending message into SQLite cache.", category: category)
        // 2. Update status to `.sending` (simulate Firebase upload beginning)
        updateMessageStatus(id: messageId, to: .sending)

        // 3. Actually send to Firebase
        messageService.sendMessage(conversationId: conversationId, senderId: senderId, text: text, type: type) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.updateMessageStatus(id: messageId, to: .sent)
                    LoggerService.shared.log(.info, "Message \(messageId) sent successfully.", category: category)
                case .failure:
                    self.updateMessageStatus(id: messageId, to: .failed)
                    LoggerService.shared.log(.error, "Failed to send message \(messageId): \(error.localizedDescription)", category: category)
                }
            }
        }
    }
    
    private func updateMessageStatus(id: String, to newStatus: MessageStatus) {
        if let index = messages.firstIndex(where: { $0.id == id }) {
            messages[index].status = newStatus
            LoggerService.shared.log(.debug, "Updated message \(id) status to \(newStatus.rawValue).", category: category)
        } else {
            LoggerService.shared.log(.warning, "Attempted to update status for unknown message ID \(id).", category: category)
        }
    }


    
    // MARK: - Mark Message as Read
    /// Marks a message as read in Firebase.
    /// - Parameters:
    ///   - messageId: The ID of the message to mark as read.
    func markMessageAsRead( messageId: String) {
        guard let conversationId = self.conversationId else {
            LoggerService.shared.log(.error, "markMessageAsRead failed: conversationId is not set.", category: category)
                return
            }
        LoggerService.shared.log(.info, "Marking message \(messageId) as read in conversation \(conversationId).", category: category)
        messageService.markMessageAsRead(conversationId: conversationId, messageId: messageId)
    }
    
    /// Marks all unread messages in the local SQLite database as read.
    /// This function iterates through all messages currently loaded in memory,
    /// and updates the local status if the message is not yet marked as read.
    ///
    /// Note: This only updates the local state; syncing to Firebase should be done separately if needed.
    func markAllAsRead() {
        LoggerService.shared.log(.info, "Marking all unread messages as read locally and remotely.", category: category)
        for message in messages where !message.isRead {
            LoggerService.shared.log(.debug, "Marking message \(message.id) as read locally.", category: category)

            // Update the message's read status in the local SQLite store
            sqliteManager.markMessageAsReadLocally(messageId: message.id)
            
            // Optionally: Also mark this message as read in Firebase
            // You could call `markMessageAsRead(conversationId: ..., messageId: message.id)` here
        }
        LoggerService.shared.log(.info, "Completed marking all unread messages as read.", category: category)

    }


    // MARK: - Cleanup
    /// Removes the Firebase listener for the current conversation to stop real-time updates.
    /// This is important for memory management and preventing unnecessary data fetching.
    func removeListener() {
        guard let conversationId = conversationId else {
            LoggerService.shared.log(.warning, "Cannot remove listener – conversationId is nil", category: category)
            return
        }
        LoggerService.shared.log(.info, "Removing message listener for conversation '\(conversationId)'", category: category)
        messageService.removeListener(for: conversationId)
    }

    
    // MARK: - Paginated Fetch
    /// Fetches a *page* of messages from Firebase that were sent **before** a specific timestamp.
    /// This is used to support pagination — the practice of loading data in chunks rather than all at once.
    /// - Parameters:
    ///   - lastMessageTimestamp: The timestamp of the oldest currently loaded message.
    ///   - completion: A closure returning a sorted array of messages fetched from Firebase.
    func fetchMessagesPaginated( lastMessageTimestamp: TimeInterval, completion: @escaping ([MessagesModel]) -> Void) {
        guard let conversationId = self.conversationId else {
            LoggerService.shared.log(.error, "fetchMessagesPaginated failed: conversationId is not set.", category: category)
                return
            }
        LoggerService.shared.log(.info, "Fetching paginated messages for conversation '\(conversationId)' before timestamp \(lastMessageTimestamp)", category: category)

        // Request a batch of messages from the backend that are older than the current oldest message.
        messageService.fetchMessagesPaginated(conversationId: conversationId, lastMessageTimestamp: lastMessageTimestamp) { messages in
            DispatchQueue.main.async {
                let sortedMessages = messages.sorted { $0.sentAt < $1.sentAt }
                LoggerService.shared.log(.info, "Fetched \(sortedMessages.count) paginated messages for conversation '\(conversationId)'", category: category)
                completion(sortedMessages)
            }
        }
    }


    // MARK: - Load More (Scroll-Up Trigger)
    /// Checks whether we need to load more messages (e.g., when user scrolls to top of chat).
    /// If more messages exist in Firebase, this function triggers a paginated fetch and inserts them at the top.
    /// - Parameter currentTopMessage: The message currently at the top of the chat list (i.e., most scrolled up).
    func loadMoreMessagesIfNeeded(currentTopMessage: MessagesModel) {
        // If there are no more messages to load, exit early.
        guard hasMoreMessages else {
            LoggerService.shared.log(.info, "No more messages to load.", category: category)
            return
        }
        
        // If we don’t know the timestamp of the oldest message yet, exit early.
        guard let oldestTimestamp = oldestMessageTimestamp else {
            LoggerService.shared.log(.info, "Oldest message timestamp unknown, cannot load more messages.", category: category)
            return }

        guard let storedConversationId = conversationId else {
            LoggerService.shared.log(.error, "Conversation ID is nil, cannot load more messages.", category: category)
            return } //  Use stored conversationId
        
        // Only load more messages if the user has scrolled to the very top of the list.
        // This prevents us from fetching more every time the user scrolls, even slightly.
        if currentTopMessage.id == messages.first?.id {
            LoggerService.shared.log(.info, "User scrolled to top. Fetching more messages older than timestamp \(oldestTimestamp) for conversation '\(storedConversationId)'.", category: category)
            // TODO: Replace `...` with a stored `conversationId` property or pass it into the function.
            fetchMessagesPaginated(conversationId: storedConversationId, lastMessageTimestamp: oldestTimestamp) { newMessages in

                // Insert the newly fetched messages at the beginning of the messages array. While filtering out duplicates
                let uniqueMessages = deduplicate(newMessages)
                LoggerService.shared.log(.info, "Fetched \(newMessages.count) messages, \(uniqueMessages.count) are unique.", category: category)
                self.messages.insert(contentsOf: uniqueMessages, at: 0)

                // Update the oldest known timestamp with the earliest message in this new batch.
                if let newOldest = newMessages.first?.sentAt {
                    self.oldestMessageTimestamp = newOldest
                    LoggerService.shared.log(.info, "Updated oldest message timestamp to \(newOldest).", category: category)
                }

                // Optionally update hasMoreMessages based on newMessages.count if you know the page size limit
                // Example: self.hasMoreMessages = newMessages.count == 20
            }
        }
    }
    
    // MARK: - Mark Message As Delivered
    /// Updates the status of a message to `.delivered`.
    /// This is typically called when the recipient's device confirms receipt of the message.
    ///
    /// - Parameters:
    ///   - conversationId: The ID of the conversation containing the message.
    ///   - messageId: The unique identifier of the message to update.
    func markMessageAsDelivered( messageId: String) {
        LoggerService.shared.log(.info, "Marking message \(messageId) as delivered.", category: category)
        updateMessageStatus(id: messageId, to: .delivered)
        // Optionally, notify backend if additional steps needed.
    }

    // MARK: - Mark Message As Read Locally
    /// Updates the status of a message to `.read` locally in the ViewModel.
    /// This should be called when the user views or opens the message.
    ///
    /// - Parameter messageId: The unique identifier of the message to update.
    func markMessageAsReadLocally(messageId: String) {
        LoggerService.shared.log(.info, "Marking message \(messageId) as read locally.", category: category)
        updateMessageStatus(id: messageId, to: .read)
    }
    
    // MARK: - Start Observing Status Updates
    /// Starts observing real-time message status updates for a given conversation,
    /// updating the ViewModel’s local messages accordingly.
    ///
    /// - Parameter conversationId: The ID of the conversation to observe.
    func startObservingStatusUpdates() {
        guard let conversationId = self.conversationId else {
            LoggerService.shared.log(.error, "Cannot start observing status updates: conversationId is nil.", category: category)
                return
            }
        LoggerService.shared.log(.info, "Starting to observe message status updates for conversation \(conversationId).", category: category)

        messageService.observeMessagesStatusUpdates(conversationId: conversationId) { [weak self] messageId, newStatus in
            DispatchQueue.main.async {
                LoggerService.shared.log(.info, "Received status update for message \(messageId): \(newStatus.rawValue).", category: self?.category ?? "Unknown")
                self?.updateMessageStatus(id: messageId, to: newStatus)
            }
        }
    }
    
    // MARK: - Resend Failed Message
    /// Attempts to resend a previously failed message.
    /// This function can be triggered when the user taps a "Retry" button
    /// or automatically when re-establishing a network connection.
    ///
    /// - Parameters:
    ///   - message: The failed message to be resent.
    ///   - conversationId: The ID of the conversation the message belongs to.
    func resendMessage(_ message: MessagesModel) {
        guard let conversationId = self.conversationId else {
            LoggerService.shared.log(.error, "Cannot resend message: conversationId is not set.", category: category)
                return
            }
        LoggerService.shared.log(.info, "Retrying to send message with id \(message.id).", category: category)

        // Optional: Set status to `.sending` so the UI reflects that a retry is in progress.
        // This prevents duplicate retry attempts and gives immediate feedback to the user.
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index].status = .sending
        }

        // Call the sendMessage function again using the same data from the failed message.
        // This reuses your existing logic in the MessageService.
        messageService.sendMessage(
                conversationId: conversationId,
                senderId: message.senderId,
                text: message.text,
                type: message.type
            ) { result in
                switch result {
                case .success:
                    LoggerService.shared.log(.info, "Message \(message.id) resend succeeded.", category: self.category)
                case .failure(let error):
                    LoggerService.shared.log(.error, "Message \(message.id) resend failed: \(error.localizedDescription)", category: self.category)
                }
            }
    }
    
    // MARK: - Retry All Failed Messages
    /// Attempts to resend all messages in the conversation that have a `.failed` status.
    /// This can be useful when the user reconnects to the internet or manually refreshes the chat.
    ///
    /// - Parameter conversationId: The ID of the conversation to retry messages for.
    func retryAllFailedMessages() {
        guard let conversationId = self.conversationId else {
            LoggerService.shared.log(.error, "Cannot retry failed messages: conversationId is not set.", category: category)
                return
            }
        // Filter out all messages with a `.failed` status.
        let failedMessages = messages.filter { $0.status == .failed }
        LoggerService.shared.log(.info, "Retrying \(failedMessages.count) failed messages for conversation \(conversationId).", category: category)
        // Loop through each failed message and try to resend it.
        for message in failedMessages {
            resendMessage(message, conversationId: conversationId)
        }
    }
    
    
    /// Debugging utility to print cached messages for a given conversation.
    /// - Parameter conversationId: The ID of the conversation whose messages should be printed.
    func printCachedMessages( ) {
        guard let conversationId = self.conversationId else {
            LoggerService.shared.log(.error, "Cannot print cached messages: conversationId is not set.", category: category)
                return
            }
        // Fetch messages stored locally for this conversation
        let cached = sqliteManager.fetchMessagesForConversation(conversationId: conversationId)
        
        // Print out message texts for quick inspection
        LoggerService.shared.log(.info, "Cached messages for conversation \(conversationId): \(messageTexts)", category: category)
    }


    
    /*
     TODOs - Suggestions and Improvements:

     1. Consistency in sentAt type:
        - Treat all 'sentAt' timestamps from Firebase Realtime Database as milliseconds.
        - Divide by 1000 to convert to seconds before creating Date objects.
        - Update fetchMessages to convert sentAt correctly, matching fetchMessagesPaginated and listenForMessageUpdates.
        - Ensure MessagesModel expects sentAt as Date consistently.

     4. Use DispatchQueue.main.async for UI updates:
        - Wrap all UI-related callbacks inside DispatchQueue.main.async to ensure main thread execution.
    */




}
