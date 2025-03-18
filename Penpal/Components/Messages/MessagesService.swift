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
    
    // MARK: - Init
    /// Initializes the service and sets up a reference to the database.
    init() {
        self.databaseRef = Database.database().reference()
    }
    
    // MARK: - Fetch Messages (Real-Time Listener)
    /// Retrieves messages for a specific conversation and listens for real-time updates.
    /// - Parameters:
    ///   - conversationId: The ID of the conversation to fetch messages from.
    ///   - completion: A closure that returns an array of `MessagesModel` objects.
    func fetchMessages(for conversationId: String, completion: @escaping ([MessagesModel]) -> Void) {
        let messagesRef = databaseRef.child("conversations").child(conversationId).child("messages")
        
        // Observe real-time updates to the messages in the conversation.
        messagesRef.observe(.value) { snapshot in
            var messages: [MessagesModel] = []
            
            // Loop through each child node and parse the message data.
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                if let messageDict = child.value as? [String: Any],
                   let id = child.key as? String,
                   let senderId = messageDict["senderId"] as? String,
                   let text = messageDict["text"] as? String,
                   let sentAt = messageDict["sentAt"] as? String,
                   let isRead = messageDict["isRead"] as? Bool,
                   let type = messageDict["type"] as? String {
                    let message = MessagesModel(id: id, senderId: senderId, text: text, sentAt: sentAt, isRead: isRead, type: type)
                    messages.append(message)
                }
            }
            
            completion(messages) // Return the parsed messages.
        }
    }
    
    // MARK: - Send a Message
    /// Sends a new message to a conversation in Firebase.
    /// - Parameters:
    ///   - conversationId: The ID of the conversation.
    ///   - senderId: The ID of the user sending the message.
    ///   - text: The content of the message.
    ///   - type: The message type (e.g., "text", "image", "file").
    func sendMessage(conversationId: String, senderId: String, text: String, type: String) {
        let messagesRef = databaseRef.child("conversations").child(conversationId).child("messages")
        let messageId = messagesRef.childByAutoId().key // Generate a unique message ID.
        
        // Construct the message dictionary.
        let messageData: [String: Any] = [
            "senderId": senderId,
            "text": text,
            "sentAt": ServerValue.timestamp(), // Firebase server timestamp.
            "isRead": false,
            "type": type
        ]
        
        // Store the message in Firebase under the generated message ID.
        messagesRef.child(messageId!).setValue(messageData)
    }
    
    // MARK: - Mark a Message as Read
    /// Updates the read status of a message in Firebase.
    /// - Parameters:
    ///   - conversationId: The ID of the conversation.
    ///   - messageId: The ID of the message to mark as read.
    func markMessageAsRead(conversationId: String, messageId: String) {
        let messageRef = databaseRef.child("conversations").child(conversationId).child("messages").child(messageId)
        messageRef.updateChildValues(["isRead": true]) // Mark the message as read.
    }
    
    // MARK: - Remove Listener
    /// Removes the real-time listener for messages in a conversation.
    /// This is useful to prevent unnecessary updates and memory leaks.
    /// - Parameter conversationId: The ID of the conversation to stop listening for updates.
    func removeListener(for conversationId: String) {
        let messagesRef = databaseRef.child("conversations").child(conversationId).child("messages")
        messagesRef.removeAllObservers() // Stop listening for real-time changes.
    }
}

