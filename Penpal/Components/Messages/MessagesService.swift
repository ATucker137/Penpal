//
//  MessagesService.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//


/*
 A bit different than most parts of the app due to it needing Realtime Databsase because I want it to be extremely responsive
 */

import Foundation
import FirebaseDatabase
import FirebaseFirestore
import Combine

// MARK: - MessagesService
/// This service handles message-related operations, including fetching,
/// sending, and updating messages in Firebase Realtime Database.
class MessagesService {
    
    // MARK: - Properties
    /// Reference to the Firebase Realtime Database.
    private var databaseRef: DatabaseReference
    private let category = "Message Service"
    
    // MARK: - Init
    /// Initializes the service and sets up a reference to the database.
    init() {
        self.databaseRef = Database.database().reference()
        LoggerService.shared.log(.info, "Initialized MessagesService", category: category)

    }
    
    // MARK: - Fetch Messages (Real-Time Listener)
    /// Retrieves messages for a specific conversation and listens for real-time updates.
    /// - Parameters:
    ///   - conversationId: The ID of the conversation to fetch messages from.
    ///   - completion: A closure that returns an array of `MessagesModel` objects.
    func fetchMessages(for conversationId: String, completion: @escaping (Result<[MessagesModel], Error>) -> Void) {
        let messagesRef = databaseRef.child("conversations").child(conversationId).child("messages")
        LoggerService.shared.log(.info, "Setting up real-time listener for conversationId: \(conversationId)", category: category)

        // Observe real-time updates to the messages in the conversation.
        messagesRef.observe(.value, with: { snapshot in
            var messages: [MessagesModel] = []

            // Loop through each child node and parse the message data.
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                if let messageDict = child.value as? [String: Any],
                   let senderId = messageDict["senderId"] as? String,
                   let text = messageDict["text"] as? String,
                   let sentAt = messageDict["sentAt"] as? TimeInterval,
                   let isRead = messageDict["isRead"] as? Bool,
                   let type = messageDict["type"] as? String {
                    let message = MessagesModel(id: child.key, senderId: senderId, text: text, sentAt: sentAt, isRead: isRead, type: type)
                    messages.append(message)
                } else {
                    LoggerService.shared.log(.warning, "Failed to parse message from snapshot: \(child.key)", category: category)

                }
            }
            LoggerService.shared.log(.debug, "Fetched \(messages.count) messages for conversationId: \(conversationId)", category: category)
            completion(.success(messages.sorted(by: { $0.sentAt < $1.sentAt })))
        }, withCancel: { error in
            LoggerService.shared.log(.error, "Failed to fetch messages for conversationId: \(conversationId): \(error.localizedDescription)", category: category)
            completion(.failure(error))
        })
    }

    
    // MARK: - Send a Message
    /// Sends a new message to a conversation in Firebase and reports result.
    /// - Parameters:
    ///   - conversationId: The ID of the conversation.
    ///   - senderId: The ID of the user sending the message.
    ///   - text: The content of the message.
    ///   - type: The message type (e.g., "text", "image", "file").
    ///   - completion: Called with success or failure once Firebase responds.
    func sendMessage(
        conversationId: String,
        senderId: String,
        text: String,
        type: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let messagesRef = databaseRef.child("conversations").child(conversationId).child("messages")
        let messageId = messagesRef.childByAutoId().key
        
        guard let messageId = messageId else {
            let errorDescription = "Failed to generate message ID."
            LoggerService.shared.log(.error, errorDescription, category: category)
                    
            completion(.failure(NSError(domain: "MessageService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to generate message ID."])))
            return
        }

        let messageData: [String: Any] = [
            "senderId": senderId,
            "text": text,
            "sentAt": ServerValue.timestamp(),
            "isRead": false,
            "type": type
        ]
        LoggerService.shared.log(.info, "Sending message with ID: \(messageId) in conversationId: \(conversationId)", category: category)
        LoggerService.shared.log(.debug, "Message content: \(messageData)", category: category)
        messagesRef.child(messageId).setValue(messageData) { error, _ in
            if let error = error {
                LoggerService.shared.log(.error, "Failed to send message: \(error.localizedDescription)", category: category)
                completion(.failure(error))
            } else {
                LoggerService.shared.log(.info, "Successfully sent message with ID: \(messageId)", category: category)
                completion(.success(()))
            }
        }
    }

    
    // MARK: - Mark a Message as Read
    /// Updates the read status of a message in Firebase.
    /// - Parameters:
    ///   - conversationId: The ID of the conversation.
    ///   - messageId: The ID of the message to mark as read.
    func markMessageAsRead(conversationId: String, messageId: String) {
        let messageRef = databaseRef.child("conversations").child(conversationId).child("messages").child(messageId)
        LoggerService.shared.log(.info, "Attempting to mark message '\(messageId)' as read in conversation '\(conversationId)'", category: category)
        // Mark the message as read.
        messageRef.updateChildValues(["isRead": true]) { error, _ in
            if let error = error {
                LoggerService.shared.log(.error, "Failed to mark message '\(messageId)' as read: \(error.localizedDescription)", category: category)
            } else {
                LoggerService.shared.log(.debug, "Successfully marked message '\(messageId)' as read", category: category)
            }
        }
    }
    
    // MARK: - Remove Listener
    /// Removes the real-time listener for messages in a conversation.
    /// This is useful to prevent unnecessary updates and memory leaks.
    /// - Parameter conversationId: The ID of the conversation to stop listening for updates.
    func removeListener(for conversationId: String) {
        let messagesRef = databaseRef.child("conversations").child(conversationId).child("messages")
        LoggerService.shared.log(.info, "Removing real-time listener for conversation '\(conversationId)'", category: category)
        messagesRef.removeAllObservers() // Stop listening for real-time changes.
    }
    
    
    // MARK: - Fetch last N messages (newest first)
    func fetchMessagesPaginated(
        conversationId: String,
        lastMessageTimestamp: TimeInterval? = nil, // Timestamp of the last fetched message, used for pagination
        limit: UInt = 20, // Limit to the number of messages to fetch at once
        completion: @escaping ([MessagesModel]) -> Void // Completion handler that returns the messages
    ) {
        LoggerService.shared.log(.info, "Fetching paginated messages for conversation '\(conversationId)' (limit: \(limit), before: \(lastMessageTimestamp ?? -1))", category: category)

        // Start building the query to fetch messages from Firebase
        var query = databaseRef
            .child("conversations") // Access the "conversations" node
            .child(conversationId) // Access the specific conversation by ID
            .child("messages") // Access the "messages" child within the conversation
            .queryOrdered(byChild: "sentAt") // Order messages by the "sentAt" field (timestamp)
            .queryLimited(toLast: limit) // Limit the number of messages fetched to the specified limit (e.g., 20)

        // If a last timestamp is provided, this fetches messages sent before that timestamp (pagination)
        if let lastTimestamp = lastMessageTimestamp {
            // Subtract a small delta (1 millisecond) to avoid fetching the message with lastTimestamp again, preventing duplicates
            let adjustedTimestamp = lastTimestamp - 1
            LoggerService.shared.log(.debug, "Applying pagination endAt timestamp: \(adjustedTimestamp)", category: category)
            query = query.queryEnding(atValue: adjustedTimestamp) // Only fetch messages strictly older than lastTimestamp
        }

        // Perform the query and handle the response
        query.observeSingleEvent(of: .value) { snapshot in
            var messages: [MessagesModel] = [] // Array to hold the fetched messages

            // Loop through the snapshot of fetched messages
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                // Convert each child into a message object
                if let messageDict = child.value as? [String: Any],
                   let id = child.key,
                   let senderId = messageDict["senderId"] as? String,
                   let text = messageDict["text"] as? String,
                   let sentAtTimestamp = messageDict["sentAt"] as? TimeInterval,
                   let isRead = messageDict["isRead"] as? Bool,
                   let type = messageDict["type"] as? String {
                    
                    // Firebase timestamps are usually stored in milliseconds, so convert to seconds
                    let sentAtDate = Date(timeIntervalSince1970: sentAtTimestamp / 1000)
                    
                    // Create a message object with the converted Date type for sentAt
                    let message = MessagesModel(id: id, senderId: senderId, text: text, sentAt: sentAtDate, isRead: isRead, type: type)
                    
                    messages.append(message) // Add the message to the array
                }
            }
            LoggerService.shared.log(.info, "Fetched \(messages.count) messages for conversation '\(conversationId)'", category: category)
            // Sort messages from oldest to newest based on sentAt before returning them
            completion(messages.sorted(by: { $0.sentAt < $1.sentAt }))

        }
    }


    
    // MARK: - Real-Time Listener for New Messages

    /// Sets up a real-time listener for newly added messages in a specific conversation.
    /// This avoids fetching the entire message history every time a new message is sent,
    /// and instead only listens for `.childAdded` events (i.e., new messages).
    ///
    /// - Parameters:
    ///   - conversationId: The unique ID of the conversation whose messages you're observing.
    ///   - onNewMessage: A closure that's called every time a new message is added. This returns a `MessagesModel` object for the new message.
    func listenForNewMessages(conversationId: String, onNewMessage: @escaping (MessagesModel) -> Void) {
        // Pointing to: /conversations/{conversationId}/messages
        let messagesRef = databaseRef
            .child("conversations")
            .child(conversationId)
            .child("messages")
        
        // MARK: - Real-time Listener for New Children (Messages)
        // This observes only newly added child nodes under "messages"
        // (i.e., it won’t trigger for existing messages already in the database).
        LoggerService.shared.log(.info, "Listening for new messages in conversation '\(conversationId)'", category: category)

        messagesRef.observe(.childAdded) { snapshot in
            
            // Each snapshot represents one new message document
            // Get the underlying dictionary from the snapshot (Firebase returns [String: Any])
            if let messageDict = snapshot.value as? [String: Any],
               
               // The message ID is the key of this snapshot (auto-generated in Firebase)
               let id = snapshot.key,
               // Safely unwrap all expected message fields
               let senderId = messageDict["senderId"] as? String,
               let text = messageDict["text"] as? String,
               let sentAt = messageDict["sentAt"] as? TimeInterval,
               let isRead = messageDict["isRead"] as? Bool,
               let type = messageDict["type"] as? String {
                
                // Convert the timestamp to String (you can also format it into Date if needed)
                let message = MessagesModel(id: snapshot.key, senderId: senderId, text: text, sentAt: sentAt, isRead: isRead, type: type)
                LoggerService.shared.log(.debug, "New message observed in conversation '\(conversationId)': id=\(id), senderId=\(senderId), type=\(type)", category: category)

                // Callback with the New Message
                // Call the passed-in closure with the new message
                onNewMessage(message)
            } else {
                LoggerService.shared.log(.warning, "Malformed message snapshot received in conversation '\(conversationId)'", category: category)
            }
        }, withCancel: { error in
            LoggerService.shared.log(.error, "Failed to observe new messages in conversation '\(conversationId)': \(error.localizedDescription)", category: category)
            // Optional: log to a service, show an alert, trigger retry, etc.
        })
    }
    
    // MARK: - Listen for Message Updates (childChanged)
    /// Listens for changes to existing messages (e.g., read status).
    /// - Parameters:
    ///   - conversationId: The ID of the conversation.
    ///   - onMessageUpdated: Callback with the updated message.
    func listenForMessageUpdates(conversationId: String, onMessageUpdated: @escaping (MessagesModel) -> Void) {
        let messagesRef = databaseRef.child("conversations").child(conversationId).child("messages")
        LoggerService.shared.log(.info, "Listening for message updates in conversation '\(conversationId)'", category: category)
        messagesRef.observe(.childChanged) { snapshot in
            if let messageDict = snapshot.value as? [String: Any],
               let id = snapshot.key as? String,
               let senderId = messageDict["senderId"] as? String,
               let text = messageDict["text"] as? String,
               let sentAtTimestamp = messageDict["sentAt"] as? TimeInterval,
               let isRead = messageDict["isRead"] as? Bool,
               let type = messageDict["type"] as? String {

                // Firebase timestamps are usually in milliseconds, so convert accordingly:
                let sentAtDate = Date(timeIntervalSince1970: sentAtTimestamp / 1000)

                let message = MessagesModel(id: id, senderId: senderId, text: text, sentAt: sentAtDate, isRead: isRead, type: type)
                LoggerService.shared.log(.debug, "Message updated in conversation '\(conversationId)': id=\(id), isRead=\(isRead)", category: category)
                onMessageUpdated(message)
            } else {
                LoggerService.shared.log(.warning, "Received malformed updated message snapshot in conversation '\(conversationId)'", category: category)
            }
        }
    }


    // MARK: - Listen for Deleted Messages (childRemoved)
    /// Listens for messages being deleted from a conversation.
    /// - Parameters:
    ///   - conversationId: The ID of the conversation.
    ///   - onMessageDeleted: Callback with the ID of the deleted message.
    func listenForDeletedMessages(conversationId: String, onMessageDeleted: @escaping (String) -> Void) {
        let messagesRef = databaseRef.child("conversations").child(conversationId).child("messages")
        LoggerService.shared.log(.info, "Listening for deleted messages in conversation '\(conversationId)'", category: category)
        messagesRef.observe(.childRemoved) { snapshot in
            let deletedMessageId = snapshot.key
            LoggerService.shared.log(.debug, "Message deleted in conversation '\(conversationId)': id=\(deletedMessageId)", category: category)
            onMessageDeleted(deletedMessageId)
        }
    }
    
    // MARK: - Observe Only Message Status Updates
    /// Sets up a Firebase real-time listener to observe only status changes on messages within a conversation.
    /// This listener only calls back when the "status" field changes on a message.
    /// - Parameters:
    ///   - conversationId: The ID of the conversation to observe.
    ///   - statusUpdateHandler: Closure called with the message ID and new status whenever a status update occurs.
    func observeMessagesStatusUpdates(conversationId: String, statusUpdateHandler: @escaping (String, MessageStatus) -> Void) {
        let messagesRef = databaseRef.child("conversations").child(conversationId).child("messages")
        LoggerService.shared.log(.info, "Observing status updates in conversation '\(conversationId)'", category: category)
        // Listen for changes to any child node (message) under "messages"
        messagesRef.observe(.childChanged) { snapshot in
            guard let dict = snapshot.value as? [String: Any] else {
                LoggerService.shared.log(.warning, "Failed to parse message data in conversation '\(conversationId)' for status update", category: category)
                return }
            
            // Extract only the "status" field from the updated message dictionary
            if let statusString = dict["status"] as? String,
               let status = MessageStatus(rawValue: statusString) {
                let messageId = snapshot.key
                LoggerService.shared.log(.debug, "Status update for message '\(messageId)' in conversation '\(conversationId)': \(status)", category: category)
                statusUpdateHandler(messageId, status) // Callback with just ID and status
            } else {
                LoggerService.shared.log(.warning, "Invalid or missing status field in message '\(snapshot.key)'", category: category)
            }
        }
    }



    // MARK: - Fetch All Messages Once (value)
    /// Loads all messages in a conversation once.
    /// - Parameters:
    ///   - conversationId: The ID of the conversation.
    ///   - onMessagesFetched: Callback with an array of all messages.
    func fetchAllMessages(conversationId: String, onMessagesFetched: @escaping ([MessagesModel]) -> Void) {
        let messagesRef = databaseRef.child("conversations").child(conversationId).child("messages")
        LoggerService.shared.log(.info, "Fetching all messages for conversation '\(conversationId)'", category: category)
        messagesRef.observeSingleEvent(of: .value) { snapshot in
            var messages: [MessagesModel] = []

            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let messageDict = childSnapshot.value as? [String: Any],
                   let senderId = messageDict["senderId"] as? String,
                   let text = messageDict["text"] as? String,
                   let sentAt = messageDict["sentAt"] as? TimeInterval,
                   let isRead = messageDict["isRead"] as? Bool,
                   let type = messageDict["type"] as? String {
                    let message = MessagesModel(
                        id: childSnapshot.key,
                        senderId: senderId,
                        text: text,
                        sentAt: "\(sentAt)",
                        isRead: isRead,
                        type: type
                    )
                    messages.append(message)
                } else {
                    LoggerService.shared.log(.warning, "Skipping invalid or malformed message entry in conversation '\(conversationId)'", category: category)
                }
            }
            LoggerService.shared.log(.info, "Fetched \(messages.count) messages from conversation '\(conversationId)'", category: category)
            onMessagesFetched(messages)
        }
    }
    
    /// Marks a single message as read in Firebase Firestore.
    ///
    /// - Parameters:
    ///   - conversationId: The ID of the conversation containing the message.
    ///   - messageId: The ID of the specific message to mark as read.
    func markMessageAsRead(conversationId: String, messageId: String) {
        // Reference to the message document in Firestore
        let messageRef = db
            .collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document(messageId)

        // Update the `isRead` field of the message to true
        messageRef.updateData(["isRead": true]) { error in
            if let error = error {
                // Log if the update fails
                LoggerService.shared.log(.error, "Failed to mark message \(messageId) as read: \(error.localizedDescription)", category: category)
            } else {
                // Confirmation log for debugging
                LoggerService.shared.log(.info, "Message \(messageId) marked as read.", category: category)
            }
        }
    }


}

