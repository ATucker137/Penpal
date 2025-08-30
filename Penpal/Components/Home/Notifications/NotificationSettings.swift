//
//  NotificationSettings.swift
//  Penpal
//
//  Created by Austin William Tucker on 6/27/25.
//

import Foundation
import SQLite3

struct NotificationSettings: Codable, Equatable {
    var allowEmailNotifications: Bool   // General email notifications toggle
    var notify1HourBefore: Bool         // Notify 1 hour before event
    var notify6HoursBefore: Bool        // Notify 6 hours before event
    var notify24HoursBefore: Bool       // Notify 24 hours before event

    // Optional: You can add other types, e.g., push notifications, SMS, etc.
    // var allowPushNotifications: Bool

    // Default initializer with reasonable defaults
    init(
        allowEmailNotifications: Bool = true,
        notify1HourBefore: Bool = false,
        notify6HoursBefore: Bool = false,
        notify24HoursBefore: Bool = true
    ) {
        self.allowEmailNotifications = allowEmailNotifications
        self.notify1HourBefore = notify1HourBefore
        self.notify6HoursBefore = notify6HoursBefore
        self.notify24HoursBefore = notify24HoursBefore
    }
    
    // MARK: -  Firestore conversions
    static func fromFireStoreData(_ data: [String: Any]) -> NotificationSettings? {
        guard let notify1 = data["notify1HourBefore"] as? Bool,
              let notify6 = data["notify6HoursBefore"] as? Bool,
              let notify24 = data["notify24HoursBefore"] as? Bool,
              let allowEmail = data["allowEmailNotifications"] as? Bool else {
            return nil
        }

        return NotificationSettings(
            allowEmailNotifications: allowEmail,
            notify1HourBefore: notify1,
            notify6HoursBefore: notify6,
            notify24HoursBefore: notify24
        )
    }
    
    // MARK: -  Creates an instance from SQLite row data
        /// - Parameter statement: SQLite statement pointer positioned at a row with columns in order:
        /// notify1hBefore, notify6hBefore, notify24hBefore, allowEmailNotifications (all Ints 0 or 1)
    static func fromSQLiteData(statement: OpaquePointer) -> NotificationSettings? {
        let notify1hBefore = sqlite3_column_int(statement, 0) != 0
        let notify6hBefore = sqlite3_column_int(statement, 1) != 0
        let notify24hBefore = sqlite3_column_int(statement, 2) != 0
        let allowEmailNotifications = sqlite3_column_int(statement, 3) != 0

        return NotificationSettings(
            allowEmailNotifications: allowEmailNotifications,
            notify1HourBefore: notify1hBefore,
            notify6HoursBefore: notify6hBefore,
            notify24HoursBefore: notify24hBefore
        )
    }

    
    // MARK: To FireStore Data
    func toFireStoreData() -> [String: Any] {
        return [
            "notify1HourBefore": notify1HourBefore,
            "notify6HoursBefore": notify6HoursBefore,
            "notify24HoursBefore": notify24HoursBefore,
            "allowEmailNotifications": allowEmailNotifications
        ]
    }
    // MARK: - Converts the instance into a dictionary suitable for SQLite insert/update
    func toSQLiteData() -> [String: Any] {
        return [
            "notify1hBefore": notify1HourBefore ? 1 : 0,
            "notify6hBefore": notify6HoursBefore ? 1 : 0,
            "notify24hBefore": notify24HoursBefore ? 1 : 0,
            "allowEmailNotifications": allowEmailNotifications ? 1 : 0
        ]
    }
}
