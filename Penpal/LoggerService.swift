//
//  LoggerService.swift
//  Penpal
//
//  Created by Austin William Tucker on 6/14/25.
//


import os

enum LogLevel {
    case info
    case warning
    case error
}

struct LoggerService {
    static let shared = LoggerService()
    
    func log(_ level: LogLevel, _ message: String, category: String = "General", privacy: Privacy = .public) {
        let logger = Logger(subsystem: "com.penpal.app", category: category)

        switch level {
        case .info:
            logger.info("\(message, privacy: privacy)")
        case .warning:
            logger.warning("\(message, privacy: privacy)")
        case .error:
            logger.error("\(message, privacy: privacy)")
        }

        #if DEBUG
        print("[\(level)] [\(category)] \(message)")
        #endif
    }
}

enum LogCategory {
    // SQLite-specific categories
    static let sqlitePenpal = "SQLite.Penpal"
    static let sqliteProfile = "SQLite.Profile"
    static let sqliteMessages = "SQLite.Messages"
    static let sqliteConversation = "SQLite.Conversation"
    static let sqliteHome = "SQLite.Home"
    static let sqliteVocabSheet = "SQLite.VocabSheet"
    static let sqliteVocabCard = "SQLite.VocabCard"
    static let sqliteCalendar = "SQLite.Calendar"
    static let sqliteMeeting = "SQLite.Meeting"
    static let sqliteNotificationsSettings = "SQLite.NotificationSettings"
    static let sqliteNotifications = "SQLite.Notifications"
    static let sqliteSwipes = "SQLite.Swipes"
    
    // General or other app areas
    static let firestoreProfile = "Firestore.Profile"
    static let firestoreVocab = "Firestore.Vocab"
    static let ui = "UI"
    static let auth = "Auth"
    static let network = "Network"
}

