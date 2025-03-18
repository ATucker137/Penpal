//
//  MessagesModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//
import Foundation

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
    var senderId: String // ID of the user who sent the message
    var text: String // The content of the message
    var sentAt: Date // Timestamp when the message was sent
    var isRead: Bool // Whether the message has been read
    var type: String // The type of the message (e.g., "text", "image", "file")
    
    // Initializer to create a new message model
    init(id: String, senderId: String, text: String, sentAt: Date, isRead: Bool, type: String) {
        self.id = id
        self.senderId = senderId
        self.text = text
        self.sentAt = sentAt
        self.isRead = isRead
        self.type = type
    }
    
    // MARK: - Date Formatting Helper (for display)
    func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss" // Customize date format for display
        return formatter.string(from: date)
    }
    
    // MARK: - Take Data From Firestore and Turns into Messages
    func fromFireStoreData(_ data: [String: Any]) -> MessagesModel {
        guard let id = data["id"] as? String,
              let senderId = data["senderId"] as? String,
              let text = data["text"] as? String,
              let sentAt = data["sentAt"] as? Date,
              let isRead = data["isRead"] as? Bool,
              let type = data["type"] as? String
        else {
            return nil
        }
        return MessagesModel(id: id, senderId: senderId, text: text, sentAt: sentAt, isRead: isRead, type: type)
    }
    
    // MARK: - Take MessagesModel data and turn into firestore realtime database
    func toFireStoreData() -> [String: Any] {
        return [
            "id" : id,
            "senderId" : senderId,
            "text" : text,
            "sentAt": sentAt,
            "isRead": isRead,
            "type": type
        ]
    }
    
    // MARK: - Convert SQLite Row to MessagesModel
    func fromSQLiteData(statement: OpaquePointer?) -> MessagesModel? {
        guard let statement = statement else { return nil }

        let id = String(cString: sqlite3_column_text(statement, 0))
        let senderId = String(cString: sqlite3_column_text(statement, 1))
        let text = String(cString: sqlite3_column_text(statement, 2))
        let sentAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 3))
        let isRead = sqlite3_column_int(statement, 4) == 1
        let type = String(cString: sqlite3_column_text(statement, 5))

        return MessagesModel(id: id, senderId: senderId, text: text, sentAt: sentAt, isRead: isRead, type: type)
    }
    
    // MARK: - Convert MessagesModel to SQLite Insertable Dictionary
    func toSQLiteData(_ message: MessagesModel) -> [String: Any] {
        return [
            "id": message.id,
            "senderId": message.senderId,
            "text": message.text,
            "sentAt": message.sentAt.timeIntervalSince1970,
            "isRead": message.isRead ? 1 : 0,
            "type": message.type
        ]
    }


}
