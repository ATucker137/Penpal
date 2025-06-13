//
//  MyCalendar.swift
//  Penpal
//
//  Created by Austin William Tucker on 12/1/24.
//
import Foundation
import SQLite3

// MARK: - MyCalendar - Model of a User's Calendar in the MVVM Structure
class MyCalendar: Codable, Identifiable {
    
    // MARK: - Properties
    var id: String // Unique identifier for this calendar instance
    var userId: String // ID of the user who owns this calendar
    var meetingIds: [String] // Stores list of meeting IDs (not full meeting objects for efficiency)
    var isSynced: Bool // Calendar is synced from Firestore
    
    // MARK: - Initializer
    init(id: String, userId: String, meetingIds: [String], isSynced: Bool) {
        self.id = id
        self.userId = userId
        self.meetingIds = meetingIds
        self.isSynced = isSynced
        
    }
    
    // MARK: - Method to Create MyCalendar from Firestore Data
    /// Converts Firestore document data into a `MyCalendar` object.
    static func fromFireStoreData(_ data: [String: Any]) -> MyCalendar? {
        guard let id = data["id"] as? String, // Validate ID
              let userId = data["userId"] as? String, // Validate UserID
              let meetingIds = data["meetingIds"] as? [String],  // Validate MeetingIDs
              let isSynced = data["isSynced"] as? Bool, else { // isSynced to Firestore
            return nil // Return nil if any data is missing or invalid
        }
        return MyCalendar(id: id, userId: userId, meetingIds: meetingIds, isSynced: isSynced)
    }
    
    // MARK: - Converts MyCalendar instance into Firestore-friendly dictionary
    func toFireStoreData() -> [String: Any] {
        return [
            "id": id,
            "userId": userId,
            "meetingIds": meetingIds,
            "isSynced": isSynced
        ]
    }
    
    // MARK: - Converts MyCalendar instance to SQLite-compatible format
    func toSQLite() -> [String: Any] {
        return [
            "id": id,
            "userId": userId,
            "meetingIds": meetingIds.joined(separator: ","), // Store as comma-separated string
            "isSynced": isSynced
        ]
    }
    
    // MARK: - Creates a MyCalendar instance from SQLite-compatible dictionary
    static func fromSQLite(_ data: [String: Any]) -> MyCalendar? {
        guard let id = data["id"] as? String,
              let userId = data["userId"] as? String,
              let meetingIdsString = data["meetingIds"] as? String,
              let isSynced = data["isSynced"] as Bool
        else {
            return nil
        }
        
        let meetingIds = meetingIdsString.isEmpty ? [] : meetingIdsString.components(separatedBy: ",")
        
        return MyCalendar(id: id, userId: userId, meetingIds: meetingIds, isSynced: isSynced)
    }
}
