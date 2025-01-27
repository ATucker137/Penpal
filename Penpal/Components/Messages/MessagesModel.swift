//
//  MessagesModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//
import Foundation

class Messages: Codable, Identifiable {
    var id: String
    var senderId: String
    var text: String
    var sentAt: String
    var isRead: String
    var type: String
    
    
    init(id: String, senderId: String, text: String, sentAt: String, isRead: String, type: String) {
        self.id = id
        self.senderId = senderId
        self.text = text
        self.sentAt = sentAt
        self.isRead = isRead
        self.type = type
    }
    
   
}
