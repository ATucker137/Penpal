//
//  MessagesModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//
import Foundation
import SQLite3

/*
 
 Why Use a Class for MessagesModel?
 
 A class is appropriate for `MessagesModel` because:
 - **Reference Semantics**: It allows instances of `MessagesModel` to be shared across multiple components of the app. This is helpful when you want to maintain a single reference to a message and reflect changes globally (e.g., marking a message as read).
 - **Shared Mutability**: Since classes are reference types, any modification made to an instance will be reflected across all references to that instance, which is ideal for scenarios like updating message status or content in real time.
 
 Why Not Use a Struct?
 
 If you don't need shared mutability or don't need to track changes across multiple components, a struct (value type) might be more efficient. However, for a model like `MessagesModel`, a class is generally preferred for better handling of dynamic, shared data.

*/



// MARK: - MessagesModel
// Model to represent a message in a conversation
class MessagesModel: Identifiable, Codable {
    var id: String // Unique identifier for the message
    var conversationId: String // ID of the conversation this message belongs to
    var senderId: String // ID of the user who sent the message
    var text: String // The content of the message
    var sentAt: Date // Timestamp when the message was sent
    var isRead: Bool // Whether the message has been read
    var type: MessageType // The type of the message (e.g., "text", "image", "file")
    var isSynced: Bool // The type of the message (e.g., "text", "image", "file")
    var status: MessageStatus // The type of the message (e.g., "text", "image", "file")
    
    // Initializer to create a new message model
    init(id: String, conversationId: String, senderId: String, text: String, sentAt: Date, isRead: Bool, type: MessageType,isSynced: Bool, status: MessageStatus) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.text = text
        self.sentAt = sentAt
        self.isRead = isRead
        self.type = type
        self.isSynced = isSynced
        self.status = status
    }
    
    // MARK: - Date Formatting Helper (for display)
    func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss" // Customize date format for display
        return formatter.string(from: date)
    }
    
    // MARK: - Take Data From Firestore and Turns into Messages
    static func fromFireStoreData(_ data: [String: Any]) -> MessagesModel? {
        guard let id = data["id"] as? String,
              let conversationId = data["conversationId"] as? String,
              let senderId = data["senderId"] as? String,
              let text = data["text"] as? String,
              let sentAt = data["sentAt"] as? Timestamp,
              let isRead = data["isRead"] as? Bool,
              let typeString = data["type"] as? String,
              let type = MessageType(rawValue: typeString),
              let isSynced = data["isSynced"] as? Bool,
              let statusString = data["status"] as? String,
              let status = MessageStatus(rawValue: statusString)
        else {
            return nil
        }

        return MessagesModel(
            id: id,
            conversationId: conversationId,
            senderId: senderId,
            text: text,
            sentAt: sentAt.dateValue(),
            isRead: isRead,
            type: type,
            isSynced: isSynced,
            status: status
        )
    }


    
    // MARK: - Take MessagesModel data and turn into firestore realtime database
    func toFireStoreData() -> [String: Any] {
        return [
            "id" : id,
            "conversationId": conversationId,
            "senderId" : senderId,
            "text" : text,
            "sentAt": sentAt,
            "isRead": isRead,
            "type": type.rawValue,
            "isSynced": isSynced,
            "status": status.rawValue // since enum need to get the raw value
        ]
    }
    
    // MARK: - Convert SQLite Row to MessagesModel
    // Turning to static function because when the function belongs to the type, not to a specific instance
    static func fromSQLiteData(statement: OpaquePointer?) -> MessagesModel? {
        guard let statement = statement else { return nil }

        let id = String(cString: sqlite3_column_text(statement, 0))
        let conversationId = String(cString: sqlite3_column_text(statement, 1))  // Added conversationId
        let senderId = String(cString: sqlite3_column_text(statement, 2))
        let text = String(cString: sqlite3_column_text(statement, 3))
        let sentAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 4))
        let isRead = sqlite3_column_int(statement, 5) == 1
        let typeRaw = String(cString: sqlite3_column_text(statement, 6))
        guard let typeEnum = MessageType(rawValue: typeRaw) else {
            return nil
        }
        let isSynced = sqlite3_column_int(statement, 7) == 1  // Ensures correct conversion to Bool
        let statusRaw = String(cString: sqlite3_column_text(statement, 8))
        guard let statusEnum = MessageStatus(rawValue: statusRaw) else {
            return nil // Fail gracefully if an invalid status is stored
        }

        return MessagesModel(
            id: id,
            conversationId: conversationId,
            senderId: senderId,
            text: text,
            sentAt: sentAt,
            isRead: isRead,
            type: typeEnum,
            isSynced: isSynced,
            status: statusEnum
        )
    }

    
    // MARK: - Convert MessagesModel to SQLite Insertable Dictionary
    static func toSQLiteData(_ message: MessagesModel) -> [String: Any] {
        return [
            "id": message.id,
            "conversationId": message.conversationId,
            "senderId": message.senderId,
            "text": message.text,
            "sentAt": message.sentAt.timeIntervalSince1970,
            "isRead": message.isRead ? 1 : 0,
            "type": message.type.rawValue,
            "isSynced": message.isSynced,
            "status": message.status.rawValue  // since enum need to get the raw value
        ]
    }
}
enum MessageStatus: String, Codable {
    case sending, sent, delivered, read, failed, pending
}

enum MessageType: String, Codable {
    case text,
    case image,
    case file
}

