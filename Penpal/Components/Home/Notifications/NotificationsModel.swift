//
//  NotificationsModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 2/12/25.
//

import Foundation

class NotificationsModel: Codable, Identifiable {
    // MARK: - Properties
    var id: String
    var userId: String
    var description: String
    var name: String
    var sentAt: Date
    var isRead: Bool
    var expirationDate: Date
    
    
    // MARK: - Iniitalizer
    init(id: String, userId: String, description: String, name: String, sentAt: Date, isRead: Boolean, expirationDate: Date) {
        self.id = id
        self.userId = userId
        self.description = description
        self.name = name
        self.sentAt = sentAt
        self.isRead = isRead
        self.expirationDate = expirationDate
    }
    
    // MARK: - Take Data From Firestore and Turns Into Notification
    static func fromFireStoreData(_ data: [String: Any]) -> NotificationsModel {
        guard let id = data["id"] as? String,
              let userId = data["userId"] as? String,
              let description = data["description"] as? String,
              let name = data["name"] as? String,
              let sentAt = data["sentAt"] as? Date,
              let isRead = data["isRead"] as? Bool,
              let expirationDate = data["expirationDate"] as? Date
        else {
            return nil
        }
        return NotificationsModel(id: id, userId: userId, description: description, name: name, sentAt: sentAt, isRead: isRead, expirationDate: expirationDate)
    }
    
    
    // MARK: - Take NotificationsModel data and puts into firestore data
    func toFireStoreData() -> [String: Any] {
        return [
            "id" : id,
            "userId" : userId,
            "description" : description,
            "name" : name,
            "sentAt" : sentAt,
            "isRead" : isRead,
            "expirationDate" : expirationDate
        ]
    }
    
}
