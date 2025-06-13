//
//  NotificationsModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 2/12/25.
//

import Foundation

class NotificationsModel: Codable, Identifiable {
    // MARK: - Properties
        
        /// Unique identifier for the notification.
        var id: String
        /// ID of the user associated with the notification.
        var userId: String
        /// Description or message of the notification.
        var description: String
        /// Name or title of the notification.
        var name: String
        /// Timestamp for when the notification was sent.
        var sentAt: Date
        /// Boolean value indicating whether the notification has been read.
        var isRead: Bool
        /// Timestamp for when the notification expires.
        var expirationDate: Date
        
        // MARK: - Initializer
        
        /// Initializes a new instance of `NotificationsModel`.
        /// - Parameters:
        ///   - id: The unique identifier for the notification.
        ///   - userId: The ID of the associated user.
        ///   - description: The message or description of the notification.
        ///   - name: The name or title of the notification.
        ///   - sentAt: Timestamp when the notification was sent.
        ///   - isRead: Boolean indicating whether the notification has been read.
        ///   - expirationDate: Timestamp indicating when the notification expires.
        init(id: String, userId: String, description: String, name: String, sentAt: Date, isRead: Bool, expirationDate: Date) {
            self.id = id
            self.userId = userId
            self.description = description
            self.name = name
            self.sentAt = sentAt
            self.isRead = isRead
            self.expirationDate = expirationDate
        }
        
        // MARK: - Convert from Firestore
        
        /// Creates a `NotificationsModel` instance from Firestore data.
        /// - Parameter data: A dictionary containing Firestore data.
        /// - Returns: A `NotificationsModel` instance if the data is valid, otherwise `nil`.
        static func fromFireStoreData(_ data: [String: Any]) -> NotificationsModel? {
            guard let id = data["id"] as? String,
                  let userId = data["userId"] as? String,
                  let description = data["description"] as? String,
                  let name = data["name"] as? String,
                  let sentAt = data["sentAt"] as? Date,
                  let isRead = data["isRead"] as? Bool,
                  let expirationDate = data["expirationDate"] as? Date else {
                return nil
            }
            
            return NotificationsModel(id: id, userId: userId, description: description, name: name, sentAt: sentAt, isRead: isRead, expirationDate: expirationDate)
        }
        
        // MARK: - Convert to Firestore
        
        /// Converts the `NotificationsModel` instance into a Firestore-compatible dictionary.
        /// - Returns: A dictionary representation of the `NotificationsModel`.
        func toFireStoreData() -> [String: Any] {
            return [
                "id": id,
                "userId": userId,
                "description": description,
                "name": name,
                "sentAt": sentAt,
                "isRead": isRead,
                "expirationDate": expirationDate
            ]
        }
        
        // MARK: - Convert to SQLite
        
        /// Converts the `NotificationsModel` instance into a SQLite-compatible dictionary.
        /// - Returns: A dictionary representation of the `NotificationsModel`.
        func toSQLiteData() -> [String: Any] {
            return [
                "id": id,
                "userId": userId,
                "description": description,
                "name": name,
                "sentAt": sentAt.timeIntervalSince1970,
                "isRead": isRead ? 1 : 0,
                "expirationDate": expirationDate.timeIntervalSince1970
            ]
        }
        
        // MARK: - Convert from SQLite
        
        /// Creates a `NotificationsModel` instance from SQLite data.
        /// - Parameter statement: SQLite statement pointer containing notification data.
        /// - Returns: A `NotificationsModel` instance if the data is valid, otherwise `nil`.
        static func fromSQLiteData(statement: OpaquePointer) -> NotificationsModel? {
            guard let id = sqlite3_column_text(statement, 0),
                  let userId = sqlite3_column_text(statement, 1),
                  let description = sqlite3_column_text(statement, 2),
                  let name = sqlite3_column_text(statement, 3) else {
                return nil
            }
            
            let sentAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 4))
            let isRead = sqlite3_column_int(statement, 5) != 0
            let expirationDate = Date(timeIntervalSince1970: sqlite3_column_double(statement, 6))
            
            return NotificationsModel(
                id: String(cString: id),
                userId: String(cString: userId),
                description: String(cString: description),
                name: String(cString: name),
                sentAt: sentAt,
                isRead: isRead,
                expirationDate: expirationDate
            )
        }
    }
