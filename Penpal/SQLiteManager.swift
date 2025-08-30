//
//  SQLiteManager.swift
//  Penpal
//
//  Created by Austin William Tucker on 3/12/25.
//
import SQLite3

class SQLiteManager {
    static let share = SQLiteManager() // Singleton Instance
    private var db: OpaquePointer?
    
    private init() {
        self.openDatabase()
        self.createPenpalsTable()
        self.createProfileTable()
        self.createMeetingsTable()
        self.createMyCalendarTable()
        self.createVocabCardTable()
        self.createVocabSheetTable()
        self.createNotificationsTable()
        self.createNotificationSettingsTable()
    }
    
    // MARK: - Creates SQLite Database
    private func openDatabase() {
        
        do {
            let fileURL = try FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask)
                .first!
                .appendingPathComponent("PenpalMatches.sqlite")
            
            if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
                print("Error opening database: \(String(cString: sqlite3_errmsg(db)!))")
            }
        } catch {
            print("File URL Error: \(error.localizedDescription)")
        }
    
    }
    
    // MARK: - Creates NotificationSettings Table
    private func createNotificationSettingsTable() {
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS NotificationSettings (
            userId TEXT PRIMARY KEY,
            allowEmailNotifications INTEGER,
            notify1hBefore INTEGER,
            notify6hBefore INTEGER,
            notify24hBefore INTEGER
        );
        """
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "✅ NotificationSettings table created successfully.", category: LogCategory.sqliteNotificationsSettings)
            } else {
                LoggerService.shared.log(.error, "❌ Failed to execute NotificationSettings table creation.", category: LogCategory.sqliteNotificationsSettings)
            }
        } else {
            LoggerService.shared.log(.error, "❌ Error preparing NotificationSettings table creation: \(String(cString: sqlite3_errmsg(db)))", category: LogCategory.sqliteNotificationsSettings)
        }
        sqlite3_finalize(statement)
    }

    
    // MARK: - Clear Local Notification Settings
    func clearLocalNotificationSettingsCache() {
        let deleteQuery = "DELETE FROM NotificationSettings;"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "✅ Local notification settings cleared successfully.", category: LogCategory.sqliteNotificationsSettings)
            } else {
                LoggerService.shared.log(.error, "❌ Failed to clear local notification settings.", category: LogCategory.sqliteNotificationsSettings)
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            LoggerService.shared.log(.error, "❌ Failed to prepare delete statement for notification settings: \(errorMessage)", category: LogCategory.sqliteNotificationsSettings)
        }

        sqlite3_finalize(statement)
    }
    
    // MARK: - Save Notification Settings to SQLite
    func saveNotificationSettingsToSQLite(_ settings: NotificationSettings) {
        let insertQuery = """
        INSERT OR REPLACE INTO NotificationSettings
        (userId, allowEmailNotifications, notify1hBefore, notify6hBefore, notify24hBefore)
        VALUES (?, ?, ?, ?, ?);
        """
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, settings.userId, -1, nil)
            sqlite3_bind_int(statement, 2, settings.allowEmailNotifications ? 1 : 0)
            sqlite3_bind_int(statement, 3, settings.notify1hBefore ? 1 : 0)
            sqlite3_bind_int(statement, 4, settings.notify6hBefore ? 1 : 0)
            sqlite3_bind_int(statement, 5, settings.notify24hBefore ? 1 : 0)

            if sqlite3_step(statement) != SQLITE_DONE {
                LoggerService.shared.log(.error, "❌ Failed to insert/update notification settings.", category: LogCategory.sqliteNotificationsSettings)
            }
        } else {
            LoggerService.shared.log(.error, "❌ Failed to prepare insert/update for notification settings.", category: LogCategory.sqliteNotificationsSettings)
        }

        sqlite3_finalize(statement)
    }

    // MARK: - Load Notification Settings from SQLite
    func loadNotificationSettingsFromSQLite(userId: String) -> NotificationSettings? {
        let query = "SELECT * FROM NotificationSettings WHERE userId = ?;"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, userId, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_ROW {
                let allowEmail = sqlite3_column_int(statement, 1) == 1
                let notify1h = sqlite3_column_int(statement, 2) == 1
                let notify6h = sqlite3_column_int(statement, 3) == 1
                let notify24h = sqlite3_column_int(statement, 4) == 1

                sqlite3_finalize(statement)

                return NotificationSettings(
                    userId: userId,
                    allowEmailNotifications: allowEmail,
                    notify1hBefore: notify1h,
                    notify6hBefore: notify6h,
                    notify24hBefore: notify24h
                )
            }
        }

        sqlite3_finalize(statement)
        return nil
    }




    // MARK: - Creates Notifications Table
    private func createNotificationsTable() {
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS Notifications (
            id TEXT PRIMARY KEY,
            userId TEXT,
            description TEXT,
            name TEXT,
            sentAt DOUBLE,
            isRead INTEGER,
            expirationDate DOUBLE,
            isSynced INTEGER
        );
        """
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "✅ Notifications table created successfully.", category: LogCategory.sqliteNotifications)
            } else {
                LoggerService.shared.log(.error, "❌ Failed to execute Notifications table creation.", category: LogCategory.sqliteNotifications)
            }
        } else {
            LoggerService.shared.log(.error, "❌ Error preparing Notifications table creation: \(String(cString: sqlite3_errmsg(db)))", category: LogCategory.sqliteNotifications)
        }
        sqlite3_finalize(statement)
    }

    
    // MARK: - Clear Local Notifications Cache
    func clearLocalNotificationsCache() {
        let deleteQuery = "DELETE FROM Notifications;"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "✅ Local notifications cache cleared successfully.", category: LogCategory.sqliteNotifications)
            } else {
                LoggerService.shared.log(.error, "❌ Failed to clear local notifications cache.", category: LogCategory.sqliteNotifications)
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            LoggerService.shared.log(.error, "❌ Failed to prepare delete statement for notifications: \(errorMessage)", category: LogCategory.sqliteNotifications)
        }

        sqlite3_finalize(statement)
    }
    
    // MARK: - Save Notifications To SQLite
    private func saveNotificationsToSQLite(_ notifications: [NotificationsModel]) {
        for notification in notifications {
            let data = notification.toSQLiteData()
            let insertQuery = """
            INSERT OR REPLACE INTO Notifications
            (id, userId, description, name, sentAt, isRead, expirationDate, isSynced)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?);
            """
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (data["id"] as! String), -1, nil)
                sqlite3_bind_text(statement, 2, (data["userId"] as! String), -1, nil)
                sqlite3_bind_text(statement, 3, (data["description"] as! String), -1, nil)
                sqlite3_bind_text(statement, 4, (data["name"] as! String), -1, nil)
                sqlite3_bind_double(statement, 5, data["sentAt"] as! Double)
                sqlite3_bind_int(statement, 6, Int32(data["isRead"] as! Int))
                sqlite3_bind_double(statement, 7, data["expirationDate"] as! Double)
                sqlite3_bind_int(statement, 8, Int32(data["isSynced"] as! Int))

                if sqlite3_step(statement) != SQLITE_DONE {
                    LoggerService.shared.log(.error, "❌ Failed to insert notification into SQLite.", category: LogCategory.sqliteNotifications)
                }
            }
            sqlite3_finalize(statement)
        }
    }

    
    // MARK: - Delete Notifications From SQLite
    func deleteNotificationFromSQLite(id: String) {
        let deleteQuery = "DELETE FROM Notifications WHERE id = ?;"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, id, -1, nil)
            if sqlite3_step(statement) != SQLITE_DONE {
                LoggerService.shared.log(.error, "❌ Failed to delete notification \(id) from SQLite.", category: LogCategory.sqliteNotifications)
            }
        }
        sqlite3_finalize(statement)
    }
    
    //MARK: - Delete Expired Notifications
    func deleteExpiredNotifications() {
        let now = Date().timeIntervalSince1970
        let deleteQuery = "DELETE FROM Notifications WHERE expirationDate < ?;"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_double(statement, 1, now)
            if sqlite3_step(statement) != SQLITE_DONE {
                LoggerService.shared.log(.error, "❌ Failed to delete expired notifications.", category: LogCategory.sqliteNotifications)
            }
        }
        sqlite3_finalize(statement)
    }


    // MARK: - Update Read Status in SQLite
    private func updateReadStatusInSQLite(notificationId: String) {
        let query = "UPDATE Notifications SET isRead = 1 WHERE id = ?;"
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, notificationId, -1, nil)
            if sqlite3_step(statement) != SQLITE_DONE {
                LoggerService.shared.log(.error, "❌ Failed to update read status in SQLite.", category: LogCategory.sqliteNotifications)
            }
        }
        sqlite3_finalize(statement)
    }

    
    //MARK: - Load Notifications From SQLite
    func loadNotificationsFromSQLite() -> [NotificationsModel] {
        let query = "SELECT * FROM Notifications;"
        var statement: OpaquePointer?
        var loaded: [NotificationsModel] = []

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                if let notification = NotificationsModel.fromSQLiteData(statement: statement!) {
                    loaded.append(notification)
                }
            }
        } else {
            LoggerService.shared.log(.error, "❌ Failed to prepare notification SELECT query.", category: LogCategory.sqliteNotifications)
        }

        sqlite3_finalize(statement)
        return loaded
    }
    
    //MARK: - Penpal Component Specific -
    // TODO: - Adjust the PenpalService to fit with SQL Lite And Needs more work overall
    
    

    // MARK: - Creates a Matches Table
    // MARK: - Creates a Penpals table (aligned with PenpalsModel)
    private func createPenpalsTable() {
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS Penpals (
            rowId INTEGER PRIMARY KEY AUTOINCREMENT,
            userId TEXT NOT NULL,
            penpalId TEXT NOT NULL,
            firstName TEXT,
            lastName TEXT,
            proficiency TEXT,
            hobbies TEXT,
            goal TEXT,
            region TEXT,
            matchScore INTEGER,
            status TEXT NOT NULL,
            profileImageURL TEXT,
            timestamp REAL NOT NULL,
            isSynced INTEGER NOT NULL DEFAULT 0
        );
        -- Ensure the UPSERTs work:
        CREATE UNIQUE INDEX IF NOT EXISTS idx_penpals_user_penpal
        ON Penpals(userId, penpalId);
        """
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "✅ Penpals table created successfully.", category: LogCategory.sqlitePenpal)
            } else {
                LoggerService.shared.log(.error, "❌ Failed to execute Penpals table creation.", category: LogCategory.sqlitePenpal)
            }
        } else {
            LoggerService.shared.log(.error, "❌ Error preparing Penpals table creation: \(String(cString: sqlite3_errmsg(db)))", category: LogCategory.sqlitePenpal)
        }
        sqlite3_finalize(statement)
    }

    // MARK: - Pull all approved Penpals for a user
    func getAllPenpals(for userId: String) -> [PenpalsModel] {
        let query = "SELECT * FROM Penpals WHERE userId = ? AND status = 'approved'"
        var statement: OpaquePointer?
        var penpals: [PenpalsModel] = []

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (userId as NSString).utf8String, -1, nil)

            // Column order per createPenpalsTable():
            // 0 rowId | 1 id | 2 userId | 3 penpalId | 4 firstName | 5 lastName
            // 6 proficiency | 7 hobbies | 8 goal | 9 region | 10 matchScore
            // 11 status | 12 profileImageURL | 13 timestamp | 14 isSynced

            let decoder = JSONDecoder()

            while sqlite3_step(statement) == SQLITE_ROW {
                let _rowId = sqlite3_column_int64(statement, 0)
                let id         = sqlite3_column_text(statement, 1).map { String(cString: $0) } ?? ""
                let userIdDb   = sqlite3_column_text(statement, 2).map { String(cString: $0) } ?? userId
                let penpalId   = sqlite3_column_text(statement, 3).map { String(cString: $0) } ?? ""
                let firstName  = sqlite3_column_text(statement, 4).map { String(cString: $0) } ?? ""
                let lastName   = sqlite3_column_text(statement, 5).map { String(cString: $0) } ?? ""

                // proficiency JSON -> LanguageProficiency
                let proficiencyJSON = sqlite3_column_text(statement, 6).map { String(cString: $0) } ?? ""
                let proficiencyData = proficiencyJSON.data(using: .utf8) ?? Data()
                let proficiency = (try? decoder.decode(LanguageProficiency.self, from: proficiencyData)) ?? .beginner

                // hobbies: comma-separated IDs -> [Hobbies]
                let hobbiesCSV = sqlite3_column_text(statement, 7).map { String(cString: $0) } ?? ""
                let hobbyIds = hobbiesCSV.split(separator: ",").map { String($0) }
                let hobbies: [Hobbies] = hobbyIds.compactMap { id in
                    Hobbies.predefinedHobbies.first(where: { $0.id == id })
                }

                // goal JSON -> Goals?
                let goalJSON = sqlite3_column_text(statement, 8).map { String(cString: $0) } ?? ""
                let goalData = goalJSON.data(using: .utf8) ?? Data()
                let goal = (goalJSON.isEmpty ? nil : (try? decoder.decode(Goals.self, from: goalData)))

                let region     = sqlite3_column_text(statement, 9).map { String(cString: $0) } ?? ""
                let matchScore = sqlite3_column_type(statement, 10) == SQLITE_NULL ? nil : Int(sqlite3_column_int(statement, 10))
                let statusRaw  = sqlite3_column_text(statement, 11).map { String(cString: $0) } ?? "pending"
                let status     = PenpalStatus(rawValue: statusRaw) ?? .pending
                let profileURL = sqlite3_column_text(statement, 12).map { String(cString: $0) } ?? ""
                let isSynced   = sqlite3_column_int(statement, 14) == 1

                let penpal = PenpalsModel(
                    userId: userIdDb,
                    penpalId: penpalId,
                    firstName: firstName,
                    lastName: lastName,
                    proficiency: proficiency,
                    hobbies: hobbies,
                    goal: goal,
                    region: region,
                    matchScore: matchScore,
                    status: status,
                    profileImageURL: profileURL,
                    isSynced: isSynced
                )

                penpals.append(penpal)
            }

            LoggerService.shared.log(.info, "Fetched \(penpals.count) approved penpals for userId: \(userId)", category: LogCategory.sqlitePenpal)
        } else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            LoggerService.shared.log(.error, "Failed to prepare getAllPenpals query for userId: \(userId). Error: \(errorMsg)", category: LogCategory.sqlitePenpal)
        }
        sqlite3_finalize(statement)
        return penpals
    }

    
    // MARK: - Count Cached Penpals
    func countCachedPenpals(for userId: String) -> Int {
        let query = "SELECT COUNT(*) FROM Penpals WHERE userId = ?"
        var statement: OpaquePointer?
        var count = 0

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (userId as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) == SQLITE_ROW {
                count = Int(sqlite3_column_int(statement, 0))
                LoggerService.shared.log(.info,"Cached penpal count for userId \(userId): \(count)",category: LogCategory.sqlitePenpal)
            } else {
                LoggerService.shared.log(
                    .warning,
                    "sqlite3_step failed while counting penpals for userId \(userId)",
                    category: LogCategory.sqlitePenpal
                )
            }
        } else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            LoggerService.shared.log(
                .error,
                "Failed to prepare COUNT query for userId \(userId). Error: \(errorMsg)",
                category: LogCategory.sqlitePenpal
            )
        }
        sqlite3_finalize(statement)
        return count
    }
    
    // MARK: - Sync Penpal
    func syncPenpal(_ penpalId: String, for userId: String) {
        let updateQuery = """
        UPDATE Penpals 
        SET isSynced = 1 
        WHERE penpalId = ? AND userId = ?;
        """

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, updateQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (penpalId as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (userId as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(
                    .info,
                    "Successfully synced penpalId \(penpalId) for userId \(userId)",
                    category: LogCategory.sqlitePenpal
                )
            } else {
                LoggerService.shared.log(
                    .warning, "Failed to sync penpalId \(penpalId) for userId \(userId). sqlite3_step did not complete as expected.",category: LogCategory.sqlitePenpal)
            }
        } else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            LoggerService.shared.log(
                .error,
                "Failed to prepare sync query for penpalId \(penpalId) and userId \(userId). Error: \(errorMsg)",
                category: LogCategory.sqlitePenpal
            )
        }
        sqlite3_finalize(statement)
    }

    // MARK:  - Decline Friend Request
    func declineFriendRequest(from penpalId: String, for userId: String) -> Bool {
        let query = "UPDATE Penpals SET status = 'declined' WHERE penpalId = ? AND userId = ?"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (penpalId as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (userId as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "Declined friend request from \(penpalId) for user \(userId)", category: LogCategory.sqlitePenpal)
                sqlite3_finalize(statement)
                return true
            } else {
                LoggerService.shared.log(.warning, "Failed to decline friend request: step failed for penpalId \(penpalId), userId \(userId)", category: LogCategory.sqlitePenpal)
            }
        } else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            LoggerService.shared.log(.error, "Failed to prepare decline friend request query for penpalId \(penpalId), userId \(userId). Error: \(errorMsg)", category: LogCategory.sqlitePenpal)
        }
        sqlite3_finalize(statement)
        return false
    }

    // MARK: - Accept Friend Request
    func acceptFriendRequest(from penpalId: String, for userId: String) -> Bool {
        let query = "UPDATE Penpals SET status = 'approved' WHERE penpalId = ? AND userId = ?"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (penpalId as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (userId as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "Accepted friend request from \(penpalId) for user \(userId)", category: LogCategory.sqlitePenpal)
                sqlite3_finalize(statement)
                return true
            }  else {
                LoggerService.shared.log(.warning, "Failed to accept friend request: step failed for penpalId \(penpalId), userId \(userId)", category: LogCategory.sqlitePenpal)
            }
        } else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            LoggerService.shared.log(.error, "Failed to prepare accept friend request query for penpalId \(penpalId), userId \(userId). Error: \(errorMsg)", category: LogCategory.sqlitePenpal)
        }
        sqlite3_finalize(statement)
        return false
    }

    // MARK: - Enforce Penpal Limit
    func enforcePenpalLimit(for userId: String, limit: Int) {
        let deleteQuery = """
        DELETE FROM Penpals 
        WHERE userId = ? 
        AND penpalId NOT IN (
            SELECT penpalId FROM Penpals 
            WHERE userId = ? 
            LIMIT ?
        );
        """
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (userId as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (userId as NSString).utf8String, -1, nil)
            sqlite3_bind_int(statement, 3, Int32(limit))

            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "Enforced penpal limit (\(limit)) for user \(userId)", category: LogCategory.sqlitePenpal)
            } else {
                LoggerService.shared.log(.warning, "Failed to enforce penpal limit for user \(userId)", category: LogCategory.sqlitePenpal)
            }
        } else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
    LoggerService.shared.log(.error, "Failed to prepare enforcePenpalLimit query for user \(userId). Error: \(errorMsg)", category: LogCategory.sqlitePenpal)
        }
        sqlite3_finalize(statement)
    }


    
    // MARK: - Delete Penpal
    func deletePenpal(penpalId: String, for userId: String) -> Bool {
        let query = "DELETE FROM Penpals WHERE penpalId = ? AND userId = ?"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (penpalId as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (userId as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "Deleted penpal \(penpalId) for user \(userId)", category: LogCategory.sqlitePenpal)
                sqlite3_finalize(statement)
                return true
            } else {
                LoggerService.shared.log(.warning, "Failed to delete penpal \(penpalId) for user \(userId)", category: LogCategory.sqlitePenpal)
            }
        } else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
    LoggerService.shared.log(.error, "Failed to prepare deletePenpal statement. Error: \(errorMsg)", category: LogCategory.sqlitePenpal)
        }
        sqlite3_finalize(statement)
        return false
    }


    
    // MARK: -  Cache matches to the SQLite database
    func cachePenpals(_ matches: [PenpalsModel]) {
        let insertQuery = """
        INSERT INTO Penpals (
            userId, penpalId, firstName, lastName, proficiency, hobbies, goal, region,
            matchScore, status, profileImageURL, timestamp, isSynced
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(userId, penpalId) DO UPDATE SET
            firstName = excluded.firstName,
            lastName = excluded.lastName,
            proficiency = excluded.proficiency,
            hobbies = excluded.hobbies,
            goal = excluded.goal,
            region = excluded.region,
            matchScore = excluded.matchScore,
            status = excluded.status,
            profileImageURL = excluded.profileImageURL,
            timestamp = excluded.timestamp,
            isSynced = excluded.isSynced;
        """

        var statement: OpaquePointer?

        for match in matches {
            if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
                
                // Encode proficiency as JSON string
                let proficiencyData = try? JSONEncoder().encode(match.proficiency)
                let proficiencyString = String(data: proficiencyData ?? Data(), encoding: .utf8) ?? ""
                
                // Encode hobbies as comma-separated IDs
                let hobbiesString = match.hobbies.map { $0.id }.joined(separator: ",")
                
                // Encode goal as JSON string (optional)
                let goalData = try? JSONEncoder().encode(match.goal)
                let goalString = String(data: goalData ?? Data(), encoding: .utf8) ?? ""

                sqlite3_bind_text(statement, 1, (match.userId as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 2, (match.penpalId as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 3, (match.firstName as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 4, (match.lastName as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 5, (proficiencyString as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 6, (hobbiesString as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 7, (goalString as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 8, (match.region as NSString).utf8String, -1, nil)
                if let score = match.matchScore {
                    sqlite3_bind_int(statement, 9, Int32(score))
                } else {
                    sqlite3_bind_null(statement, 9)
                }
                sqlite3_bind_text(statement, 10, (match.status.rawValue as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 11, (match.profileImageURL as NSString).utf8String, -1, nil)
                sqlite3_bind_double(statement, 12, Date().timeIntervalSince1970)
                sqlite3_bind_int(statement, 13, match.isSynced ? 1 : 0)

                if sqlite3_step(statement) == SQLITE_DONE {
                    LoggerService.shared.log(.info, "✅ Penpal cached successfully for \(match.penpalId)", category: LogCategory.sqlitePenpal)
                } else {
                    LoggerService.shared.log(.warning, "⚠️ Failed to cache penpal \(match.penpalId)", category: LogCategory.sqlitePenpal)
                }
            } else {
                let errorMsg = String(cString: sqlite3_errmsg(db))
                LoggerService.shared.log(.error, "❌ Failed to prepare insert for penpal \(match.penpalId): \(errorMsg)", category: LogCategory.sqlitePenpal)
            }
            sqlite3_finalize(statement)
        }
    }

    
    // MARK: - Send Friend Request
    func sendFriendRequest(to penpalId: String, from userId: String) -> Bool {
        let query = """
        INSERT INTO Penpals (userId, penpalId, status, isSynced, timestamp)
        VALUES (?, ?, 'pending', 0, strftime('%s','now'))
        ON CONFLICT(userId, penpalId) DO UPDATE SET status='pending', isSynced=0, timestamp=strftime('%s','now');
        """
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (userId as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (penpalId as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "Sent friend request from \(userId) to \(penpalId)", category: LogCategory.sqlitePenpal)
                sqlite3_finalize(statement)
                return true
            } else {
                let errorMsg = String(cString: sqlite3_errmsg(db))
                LoggerService.shared.log(.error, "Failed to send friend request from \(userId) to \(penpalId): \(errorMsg)", category: LogCategory.sqlitePenpal)
                }
        } else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            LoggerService.shared.log(.error, "Failed to prepare friend request insert: \(errorMsg)", category: LogCategory.sqlitePenpal)
        }
        
        sqlite3_finalize(statement)
        return false
    }

    // MARK: -  Fetches cached matches for a user from SQLite
    func fetchCachedPenpals(for userId: String) -> [PenpalsModel] {
        // Column order per createPenpalsTable():
        // 0 rowId | 1 id | 2 userId | 3 penpalId | 4 firstName | 5 lastName
        // 6 proficiency(JSON) | 7 hobbies(CSV IDs) | 8 goal(JSON) | 9 region
        // 10 matchScore | 11 status | 12 profileImageURL | 13 timestamp | 14 isSynced

        let query = "SELECT * FROM Penpals WHERE userId = ? ORDER BY matchScore DESC"
        var statement: OpaquePointer?
        var matches: [PenpalsModel] = []

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (userId as NSString).utf8String, -1, nil)

            let decoder = JSONDecoder()

            while sqlite3_step(statement) == SQLITE_ROW {
                // Safe string fetch helper
                func colString(_ idx: Int32) -> String {
                    guard let cstr = sqlite3_column_text(statement, idx) else { return "" }
                    return String(cString: cstr)
                }

                let penpalId = colString(3)
                let firstName = colString(4)
                let lastName = colString(5)

                // proficiency JSON -> LanguageProficiency (default to .beginner if decoding fails)
                let proficiencyJSON = colString(6)
                let proficiencyData = proficiencyJSON.data(using: .utf8) ?? Data()
                let proficiency = (try? decoder.decode(LanguageProficiency.self, from: proficiencyData)) ?? .beginner

                // hobbies CSV IDs -> [Hobbies]
                let hobbiesCSV = colString(7)
                let hobbyIds = hobbiesCSV.split(separator: ",").map { String($0) }
                let hobbies: [Hobbies] = hobbyIds.compactMap { id in
                    Hobbies.predefinedHobbies.first(where: { $0.id == id })
                }

                // goal JSON -> Goals?
                let goalJSON = colString(8)
                let goal: Goals? = {
                    guard !goalJSON.isEmpty, let data = goalJSON.data(using: .utf8) else { return nil }
                    return try? decoder.decode(Goals.self, from: data)
                }()

                let region = colString(9)
                let matchScore = (sqlite3_column_type(statement, 10) == SQLITE_NULL) ? nil : Int(sqlite3_column_int(statement, 10))
                let statusRaw = colString(11)
                let status = PenpalStatus(rawValue: statusRaw) ?? .pending
                let profileImageURL = colString(12)
                let isSynced = sqlite3_column_int(statement, 14) == 1

                let match = PenpalsModel(
                    userId: userId,                
                    penpalId: penpalId,
                    firstName: firstName,
                    lastName: lastName,
                    proficiency: proficiency,
                    hobbies: hobbies,
                    goal: goal,
                    region: region,
                    matchScore: matchScore,
                    status: status,
                    profileImageURL: profileImageURL,
                    isSynced: isSynced
                )
                matches.append(match)
            }

            LoggerService.shared.log(.info, "Fetched \(matches.count) cached penpals for user \(userId)", category: LogCategory.sqlitePenpal)
        } else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            LoggerService.shared.log(.error, "Failed to prepare fetchCachedPenpals query: \(errorMsg)", category: LogCategory.sqlitePenpal)
        }

        sqlite3_finalize(statement)
        return matches
    }

    
    // MARK: - Clears matches older than 7 days
    func clearOldPenpals() {
        let cutoffTime = Date().timeIntervalSince1970 - (7 * 24 * 60 * 60) // 7 days in seconds
        let deleteQuery = "DELETE FROM Penpals WHERE timestamp < ?"

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_double(statement, 1, cutoffTime)

            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "Old penpals cleared successfully (older than 7 days)", category: LogCategory.sqlitePenpal)
            } else {
                LoggerService.shared.log(.warning, "Failed to clear old penpals: step execution failed", category: LogCategory.sqlitePenpal)
            }
        } else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            LoggerService.shared.log(.error, "Failed to prepare clearOldPenpals query: \(errorMsg)", category: LogCategory.sqlitePenpal)
        }
        sqlite3_finalize(statement)
    }
    
    // MARK: - Swipe Specific -
    //MARK: - Create Swipes Quota Table
    private func createSwipeQuotaTable() {
        let sql = """
        CREATE TABLE IF NOT EXISTS SwipeQuota (
            userId   TEXT PRIMARY KEY,
            day      TEXT NOT NULL,            -- "yyyy-MM-dd"
            used     INTEGER NOT NULL DEFAULT 0,
            max      INTEGER NOT NULL DEFAULT 40,
            updatedAt REAL NOT NULL            -- epoch seconds
        );
        """
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_DONE {
                LoggerService.shared.log(.info, "✅ SwipeQuota table ready", category: LogCategory.sqliteSwipes)
            } else {
                LoggerService.shared.log(.warning, "⚠️ SwipeQuota create step failed", category: LogCategory.sqliteSwipes)
            }
        } else {
            LoggerService.shared.log(.error, "❌ SwipeQuota create prepare error: \(String(cString: sqlite3_errmsg(db)))", category: LogCategory.sqliteSwipes)
        }
        sqlite3_finalize(stmt)
    }
    
    func fetchSwipeStatusLocal(userId: String, defaultMax: Int) -> (remaining: Int, windowEndsAt: Date) {
        let dayKey = todayKey()
        let select = "SELECT day, used, max FROM SwipeQuota WHERE userId = ?"
        var stmt: OpaquePointer?

        var day = dayKey
        var used = 0
        var maxPerDay = defaultMax

        if sqlite3_prepare_v2(db, select, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (userId as NSString).utf8String, -1, nil)
            if sqlite3_step(stmt) == SQLITE_ROW {
                day       = String(cString: sqlite3_column_text(stmt, 0))
                used      = Int(sqlite3_column_int(stmt, 1))
                maxPerDay = Int(sqlite3_column_int(stmt, 2))
            }
        } else {
            LoggerService.shared.log(.error, "fetchSwipeStatusLocal prepare failed: \(String(cString: sqlite3_errmsg(db)))", category: LogCategory.sqliteSwipes)
        }
        sqlite3_finalize(stmt)

        // rollover if needed
        if day != dayKey {
            // reset
            let up = """
            INSERT INTO SwipeQuota(userId, day, used, max, updatedAt)
            VALUES (?, ?, 0, ?, strftime('%s','now'))
            ON CONFLICT(userId) DO UPDATE SET day=excluded.day, used=0, max=excluded.max, updatedAt=excluded.updatedAt;
            """
            var upStmt: OpaquePointer?
            if sqlite3_prepare_v2(db, up, -1, &upStmt, nil) == SQLITE_OK {
                sqlite3_bind_text(upStmt, 1, (userId as NSString).utf8String, -1, nil)
                sqlite3_bind_text(upStmt, 2, (dayKey as NSString).utf8String, -1, nil)
                sqlite3_bind_int(upStmt, 3, Int32(maxPerDay))
                _ = sqlite3_step(upStmt)
            }
            sqlite3_finalize(upStmt)
            used = 0
            day = dayKey
        }

        let remaining = max(0, maxPerDay - used)
        return (remaining, startOfTomorrow())
    }
    
    func tryConsumeSwipeLocal(userId: String, maxPerDay: Int) -> Result<Int, Error> {
        let dayKey = todayKey()

        // ensure row exists & rollover if needed
        let upsert = """
        INSERT INTO SwipeQuota(userId, day, used, max, updatedAt)
        VALUES (?, ?, 0, ?, strftime('%s','now'))
        ON CONFLICT(userId) DO UPDATE SET
          day = CASE WHEN SwipeQuota.day <> excluded.day THEN excluded.day ELSE SwipeQuota.day END,
          used = CASE WHEN SwipeQuota.day <> excluded.day THEN 0 ELSE SwipeQuota.used END,
          max = excluded.max,
          updatedAt = excluded.updatedAt;
        """

        let consume = """
        UPDATE SwipeQuota
        SET used = used + 1, updatedAt = strftime('%s','now')
        WHERE userId = ? AND day = ? AND used < max;
        """

        var up: OpaquePointer?; var c: OpaquePointer?
        sqlite3_exec(db, "BEGIN IMMEDIATE", nil, nil, nil)

        defer {
            sqlite3_finalize(up)
            sqlite3_finalize(c)
            sqlite3_exec(db, "COMMIT", nil, nil, nil)
        }

        // upsert/rollover
        guard sqlite3_prepare_v2(db, upsert, -1, &up, nil) == SQLITE_OK else {
            let msg = String(cString: sqlite3_errmsg(db))
            LoggerService.shared.log(.error, "tryConsumeSwipeLocal upsert prepare failed: \(msg)", category: .sqlitePenpal)
            return .failure(NSError(domain: "sqlite", code: 1, userInfo: [NSLocalizedDescriptionKey: msg]))
        }
        sqlite3_bind_text(up, 1, (userId as NSString).utf8String, -1, nil)
        sqlite3_bind_text(up, 2, (dayKey as NSString).utf8String, -1, nil)
        sqlite3_bind_int(up, 3, Int32(maxPerDay))
        _ = sqlite3_step(up)

        // try consume
        guard sqlite3_prepare_v2(db, consume, -1, &c, nil) == SQLITE_OK else {
            let msg = String(cString: sqlite3_errmsg(db))
            LoggerService.shared.log(.error, "tryConsumeSwipeLocal consume prepare failed: \(msg)", category: .sqlitePenpal)
            return .failure(NSError(domain: "sqlite", code: 2, userInfo: [NSLocalizedDescriptionKey: msg]))
        }
        sqlite3_bind_text(c, 1, (userId as NSString).utf8String, -1, nil)
        sqlite3_bind_text(c, 2, (dayKey as NSString).utf8String, -1, nil)

        if sqlite3_step(c) == SQLITE_DONE, sqlite3_changes(db) > 0 {
            // success → return remaining
            let (remaining, _) = fetchSwipeStatusLocal(userId: userId, defaultMax: maxPerDay)
            LoggerService.shared.log(.info, "tryConsumeSwipeLocal: success, remaining=\(remaining)", category: .sqlitePenpal)
            return .success(remaining)
        } else {
            // quota reached → make it match remote (-1 means blocked)
            LoggerService.shared.log(.info, "tryConsumeSwipeLocal: blocked (quota reached)", category: .sqlitePenpal)
            return .success(-1)
        }
    }

    @discardableResult
    func setDailySwipeAllowanceLocal(userId: String, newMax: Int) -> Bool {
        let up = """
        INSERT INTO SwipeQuota(userId, day, used, max, updatedAt)
        VALUES (?, ?, 0, ?, strftime('%s','now'))
        ON CONFLICT(userId) DO UPDATE SET max = excluded.max, updatedAt = excluded.updatedAt;
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, up, -1, &stmt, nil) == SQLITE_OK else {
            LoggerService.shared.log(.error, "setDailySwipeAllowanceLocal prepare failed", category: .sqlitePenpal)
            return false
        }
        sqlite3_bind_text(stmt, 1, (userId as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (todayKey() as NSString).utf8String, -1, nil)
        sqlite3_bind_int(stmt, 3, Int32(max(0, newMax)))
        let ok = sqlite3_step(stmt) == SQLITE_DONE
        sqlite3_finalize(stmt)
        return ok
    }

    @discardableResult
    func grantBonusSwipesLocal(userId: String, amount: Int, maxPerDay: Int) -> Bool {
        guard amount > 0 else { return false }
        let dayKey = todayKey()
        let sql = """
        UPDATE SwipeQuota
        SET used = MAX(0, used - ?), updatedAt = strftime('%s','now')
        WHERE userId = ? AND day = ?;
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            LoggerService.shared.log(.error, "grantBonusSwipesLocal prepare failed", category: .sqlitePenpal)
            return false
        }
        sqlite3_bind_int(stmt, 1, Int32(amount))
        sqlite3_bind_text(stmt, 2, (userId as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 3, (dayKey as NSString).utf8String, -1, nil)
        let ok = sqlite3_step(stmt) == SQLITE_DONE
        sqlite3_finalize(stmt)
        return ok
    }
    
    func upsertSwipeStatusLocal(userId: String, remaining: Int, maxPerDay: Int) {
        let dayKey = todayKey()
        let used = max(0, maxPerDay - remaining)
        let sql = """
        INSERT INTO SwipeQuota (userId, day, used, max, updatedAt)
        VALUES (?, ?, ?, ?, strftime('%s','now'))
        ON CONFLICT(userId) DO UPDATE SET
          day = excluded.day,
          used = excluded.used,
          max = excluded.max,
          updatedAt = excluded.updatedAt;
        """
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (userId as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (dayKey as NSString).utf8String, -1, nil)
            sqlite3_bind_int(stmt, 3, Int32(used))
            sqlite3_bind_int(stmt, 4, Int32(maxPerDay))
            _ = sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }

    
    // MARK: - Conversation Specific -
    
    // MARK: - Create Conversations Table (Updated)
    private func createConversationsTable() {
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS Conversations (
            id TEXT PRIMARY KEY,
            participants TEXT NOT NULL,     -- Stored as a JSON array
            lastMessage TEXT,
            lastUpdated REAL NOT NULL,      -- Stored as a timestamp (timeIntervalSince1970)
            isSynced INTEGER NOT NULL DEFAULT 0
        );
        """

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "Conversations table created successfully.", category: LogCategory.sqliteConversation)
            } else {
                LoggerService.shared.log(.warning, "Failed to create Conversations table: step execution failed", category: LogCategory.sqliteConversation)
            }
        }else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            LoggerService.shared.log(.error, "Error preparing Conversations table creation statement: \(errorMsg)", category: LogCategory.sqliteConversation)
        }
        sqlite3_finalize(statement)
    }

    //MARK: - Delete Conversations
    func deleteConversation(conversationId: String) {
        let deleteQuery = "DELETE FROM Conversations WHERE id = ?;"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (conversationId as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "Conversation deleted locally: \(conversationId)", category: LogCategory.sqliteConversation)
            } else {
                LoggerService.shared.log(.warning, "Failed to delete conversation locally: \(conversationId)", category: LogCategory.sqliteConversation)
            }
        } else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            LoggerService.shared.log(.error, "Failed to prepare delete statement for conversation \(conversationId): \(errorMsg)", category: LogCategory.sqliteConversation)
        }
        sqlite3_finalize(statement)
    }
    // MARK: - Insert Single Conversation (Updated for Participants Array)
    func insertSingleConversation(
        conversationId: String,
        participants: [String],
        lastMessage: String?,
        lastUpdated: Date = Date(),
        isSynced: Bool = false
    ) {
        let insertQuery = """
        INSERT OR REPLACE INTO Conversations (id, participants, lastMessage, lastUpdated, isSynced)
        VALUES (?, ?, ?, ?, ?);
        """

        var statement: OpaquePointer?
        
        // Convert participants array to JSON string
        guard let participantsData = try? JSONEncoder().encode(participants),
              let participantsJson = String(data: participantsData, encoding: .utf8) else {
            LoggerService.shared.log(.error, "Failed to encode participants array.", category: LogCategory.sqliteConversation)
            return
        }

        if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (conversationId as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (participantsJson as NSString).utf8String, -1, nil)

            if let lastMessage = lastMessage {
                sqlite3_bind_text(statement, 3, (lastMessage as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(statement, 3)
            }

            sqlite3_bind_double(statement, 4, lastUpdated.timeIntervalSince1970)
            sqlite3_bind_int(statement, 5, isSynced ? 1 : 0)

            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "Inserted/updated conversation: \(conversationId)", category: LogCategory.sqliteConversation)
            } else {
                LoggerService.shared.log(.warning, "Failed to insert/update conversation: \(conversationId)", category: LogCategory.sqliteConversation)
            }
        } else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            LoggerService.shared.log(.error, "Error preparing insert for conversation \(conversationId): \(errorMsg)", category: LogCategory.sqliteConversation)
        }

        sqlite3_finalize(statement)
    }



    // MARK: - Cache Conversations
    func cacheConversations(_ conversations: [ConversationsModel]) {
        let insertQuery = """
        INSERT OR REPLACE INTO Conversations (id, participants, lastMessage, lastUpdated, isSynced)
        VALUES (?, ?, ?, ?, ?);
        """

        var statement: OpaquePointer?

        for convo in conversations {
            if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
                // Bind id
                sqlite3_bind_text(statement, 1, (convo.id as NSString).utf8String, -1, nil)

                // Convert participants array to JSON string
                if let participantsData = try? JSONEncoder().encode(convo.participants),
                   let participantsJSON = String(data: participantsData, encoding: .utf8) {
                    sqlite3_bind_text(statement, 2, (participantsJSON as NSString).utf8String, -1, nil)
                } else {
                    sqlite3_bind_null(statement, 2)
                    LoggerService.shared.log(.warning, "Failed to encode participants for conversation: \(convo.id)", category: LogCategory.sqliteConversation)

                }

                // Bind lastMessage
                if let lastMessage = convo.lastMessage {
                    sqlite3_bind_text(statement, 3, (lastMessage as NSString).utf8String, -1, nil)
                } else {
                    sqlite3_bind_null(statement, 3)
                }

                // Bind lastUpdated as timeIntervalSince1970
                sqlite3_bind_double(statement, 4, convo.lastUpdated.timeIntervalSince1970)

                // Bind isSynced (1 or 0)
                sqlite3_bind_int(statement, 5, convo.isSynced ? 1 : 0)

                // Execute and check result
                if sqlite3_step(statement) == SQLITE_DONE {
                    LoggerService.shared.log(.info, "Cached conversation: \(convo.id)", category: LogCategory.sqliteConversation)
                } else {
                    LoggerService.shared.log(.error, "Failed to cache conversation: \(convo.id)", category: LogCategory.sqliteConversation)
                }
            } else {
                let errorMsg = String(cString: sqlite3_errmsg(db))
                LoggerService.shared.log(.error, "Error preparing cache insert statement for conversation \(convo.id): \(errorMsg)", category: LogCategory.sqliteConversation)
            }
            sqlite3_finalize(statement)
        }
    }

    //MARK: - Fetch Covnersations
    func fetchConversations(for userId: String) -> [ConversationsModel] {
        let query = "SELECT * FROM Conversations ORDER BY lastUpdated DESC;"
        var statement: OpaquePointer?
        var conversations: [ConversationsModel] = []

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                if let convo = fromConversationSQLite(statement: statement) {
                    // Filter by checking if userId is in participants
                    if convo.participants.contains(userId) {
                        conversations.append(convo)
                    }
                } else {
                    LoggerService.shared.log(.warning, "Skipped row in Conversations due to parsing failure", category: LogCategory.sqliteConversation)
                }
            }
            LoggerService.shared.log(.info, "Fetched \(conversations.count) conversations for user \(userId)", category: LogCategory.sqliteConversation)

        } else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            LoggerService.shared.log(.error, "Failed to prepare fetchConversations query: \(errorMsg)", category: LogCategory.sqliteConversation)
        }

        sqlite3_finalize(statement)
        return conversations
    }




    
    
    
    // MARK: - Fetch Messages for a Specific Conversation
    func fetchMessagesForConversation(conversationId: String) -> [MessagesModel] {
        let query = "SELECT * FROM Messages WHERE conversationId = ? ORDER BY sentAt ASC;"
        var statement: OpaquePointer?
        var messages: [MessagesModel] = []

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (conversationId as NSString).utf8String, -1, nil)

            while sqlite3_step(statement) == SQLITE_ROW {
                if let message = fromSQLiteData(statement: statement) {
                    messages.append(message)
                } else {
                    LoggerService.shared.log(.warning, "Failed to decode message row for conversationId: \(conversationId)", category: LogCategory.sqliteMessages)
                }
            }
            LoggerService.shared.log(.info, "Fetched \(messages.count) messages for conversation \(conversationId)", category: LogCategory.sqliteMessages)

        } else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            LoggerService.shared.log(.error, "Failed to prepare fetchMessagesForConversation statement: \(errorMsg)", category: LogCategory.sqliteMessages)
        }
        
        sqlite3_finalize(statement)
        return messages
    }
    
    // MARK: - Update Last Message
    func updateLastMessage(conversationId: String, message: String, lastUpdated: Date) {
        let updateQuery = """
        UPDATE Conversations
        SET lastMessage = ?, lastUpdated = ?, isSynced = 0
        WHERE id = ?;
        """

        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, updateQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (message as NSString).utf8String, -1, nil)
            sqlite3_bind_double(statement, 2, lastUpdated.timeIntervalSince1970)
            sqlite3_bind_text(statement, 3, (conversationId as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "Successfully updated local last message for conversation \(conversationId)", category: LogCategory.sqliteConversation)
            } else {
                LoggerService.shared.log(.error, "Failed to update last message locally for conversation \(conversationId)", category: LogCategory.sqliteConversation)
            }
        } else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            LoggerService.shared.log(.error, "Error preparing last message update for \(conversationId): \(errorMsg)", category: LogCategory.sqliteConversation)
        }

        sqlite3_finalize(statement)
    }
    
    // MARK: - Clear Local Cache on Logout
    /// This function removes all locally cached conversation data.
    /// It is called when the user logs out to:
    /// - Protect user privacy (in case another user logs in)
    /// - Prevent showing outdated/stale data
    /// - Avoid data sync conflicts with Firestore
    func clearLocalConversationCache() {
        let deleteQuery = "DELETE FROM Conversations;"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "Local conversation cache cleared successfully.", category: LogCategory.sqliteConversation)
            } else {
                LoggerService.shared.log(.error, "Failed to clear local conversation cache.", category: LogCategory.sqliteConversation)
            }
        } else {
            LoggerService.shared.log(.error, "Failed to prepare statement for clearing local conversation cache.", category: LogCategory.sqliteConversation)
        }

        sqlite3_finalize(statement)
    }

    
    // MARK: - Search Conversations
    func searchConversations(query: String, userId: String) -> [ConversationsModel] {
        let searchQuery = """
        SELECT * FROM Conversations
        WHERE userId = ? AND lastMessage LIKE ?
        ORDER BY lastUpdated DESC;
        """
        var statement: OpaquePointer?
        var results: [ConversationsModel] = []

        if sqlite3_prepare_v2(db, searchQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (userId as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, ("%\(query)%" as NSString).utf8String, -1, nil)

            while sqlite3_step(statement) == SQLITE_ROW {
                if let convo = fromConversationSQLite(statement: statement) {
                    results.append(convo)
                }
            }
            LoggerService.shared.log(.info, "Search completed with \(results.count) result(s) for query: '\(query)'", category: LogCategory.sqliteConversation)

        } else {
            LoggerService.shared.log(.error, "Search query preparation failed for Conversations.", category: LogCategory.sqliteConversation)
        }

        sqlite3_finalize(statement)
        return results
    }
    
    // MARK: - Fetch Unsynced Conversations
    // If you're syncing data with a remote server, this will help.
    func fetchUnsyncedConversations() -> [ConversationsModel] {
        let query = "SELECT * FROM Conversations WHERE isSynced = 0;"
        var statement: OpaquePointer?
        var unsynced: [ConversationsModel] = []

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                if let convo = fromConversationSQLite(statement: statement) {
                    unsynced.append(convo)
                }
            }
            LoggerService.shared.log(.info, "Fetched \(unsynced.count) unsynced conversations from SQLite.", category: LogCategory.sqliteConversation)

        } else {
            LoggerService.shared.log(.error, "Failed to prepare statement for fetching unsynced conversations.", category: LogCategory.sqliteConversation)
        }

        sqlite3_finalize(statement)
        return unsynced
    }



    
    // MARK: - Messages Specific -
    // MARK: - Create Messages Table
    private func createMessagesTable() {
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS Messages (
            id TEXT PRIMARY KEY,
            senderId TEXT NOT NULL,
            text TEXT NOT NULL,
            sentAt REAL NOT NULL,
            isRead INTEGER NOT NULL DEFAULT 0,
            type TEXT NOT NULL,
            isSynced INTEGER NOT NULL DEFAULT 0,
            status TEXT NOT NULL DEFAULT 'pending'
        );
        """

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "Messages table created successfully.", category: LogCategory.sqliteMessages)
            } else {
                LoggerService.shared.log(.error, "Failed to create Messages table.", category: LogCategory.sqliteMessages)
            }
        } else {
            LoggerService.shared.log(.error, "Error preparing Messages table creation statement.", category: LogCategory.sqliteMessages)
        }
        sqlite3_finalize(statement)
    }

    
    // MARK: - Cache Messages to the SQLite database
    func cacheMessages(_ messages: [MessagesModel]) {
        let insertQuery = """
        INSERT OR REPLACE INTO Messages (id, senderId, text, sentAt, isRead, type, isSynced, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        """

        var statement: OpaquePointer?

        for message in messages {
            if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (message.id as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 2, (message.senderId as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 3, (message.text as NSString).utf8String, -1, nil)
                sqlite3_bind_double(statement, 4, message.sentAt.timeIntervalSince1970)
                sqlite3_bind_int(statement, 5, message.isRead ? 1 : 0)
                sqlite3_bind_text(statement, 6, (message.type.rawValue as NSString).utf8String, -1, nil)
                sqlite3_bind_int(statement, 7, message.isSynced ? 1 : 0)
                sqlite3_bind_text(statement, 8, (message.status.rawValue as NSString).utf8String, -1, nil)

                if sqlite3_step(statement) == SQLITE_DONE {
                    LoggerService.shared.log(.info, "Message cached: \(message.id)", category: LogCategory.sqliteMessages)
                } else {
                    LoggerService.shared.log(.error, "Failed to cache message: \(message.id)", category: LogCategory.sqliteMessages)
                }
            }  else {
                LoggerService.shared.log(.error, "Failed to prepare message insert statement for: \(message.id)", category: LogCategory.sqliteMessages)
            }
            sqlite3_finalize(statement)
        }
    }
    
    // MARK: - Clear Local Message Cache
    /// Deletes all locally cached messages from SQLite.
    /// Called during logout to:
    /// - Protect user privacy
    /// - Prevent message data from showing under the wrong user
    /// - Clear stale or unsynced message data
    func clearLocalMessageCache() {
        let deleteQuery = "DELETE FROM Messages;" // Adjust table name if different
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "Local message cache cleared successfully.", category: LogCategory.sqliteMessages)
            } else {
                LoggerService.shared.log(.error, "Failed to clear local message cache.", category: LogCategory.sqliteMessages)
            }
        } else {
            LoggerService.shared.log(.error, "Failed to prepare delete statement for message cache.", category: LogCategory.sqliteMessages)
        }

        sqlite3_finalize(statement)
    }


    // MARK: - Fetch All Messages from SQLite
    func fetchMessages() -> [MessagesModel] {
        let query = "SELECT * FROM Messages ORDER BY sentAt DESC;"
        var statement: OpaquePointer?
        var messages: [MessagesModel] = []

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                if let message = fromSQLiteData(statement: statement) {
                    messages.append(message)
                }
            }
        } else {
            LoggerService.shared.log(.error, "Error fetching messages.", category: LogCategory.sqliteMessages)
        }
        
        sqlite3_finalize(statement)
        return messages
    }
    
    // MARK: - Insert Message
    func insertMessage(_ message: MessagesModel) {
        cacheMessages([message])
    }
    
    // MARK: - Update Message Status
    func updateMessageStatus(messageId: String, status: MessageStatus) {
        let updateQuery = "UPDATE Messages SET status = ? WHERE id = ?;"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, updateQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (status.rawValue as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (messageId as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) != SQLITE_DONE {
                LoggerService.shared.log(.error, "Failed to update message status for ID: \(messageId)", category: LogCategory.sqliteMessages)
            }
        } else {
            LoggerService.shared.log(.error, "Failed to prepare update statement for message status.", category: LogCategory.sqliteMessages)
        }

        sqlite3_finalize(statement)
    }
    
    // MARK: - Insert or Update Message
    func insertOrUpdateMessages(_ messages: [MessagesModel]) {
        cacheMessages(messages)
    }
    
    // MARK: - Fetch Failed Messages
    func fetchFailedMessages(conversationID: String) -> [MessagesModel] {
        let query = "SELECT * FROM Messages WHERE status = 'failed' OR isSynced = 0;"
        var statement: OpaquePointer?
        var failedMessages = [MessagesModel]()

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                if let message = parseMessageRow(statement: statement) {
                    failedMessages.append(message)
                }
            }
        } else {
            LoggerService.shared.log(.error, "Failed to prepare fetchFailedMessages query.", category: LogCategory.sqliteMessages)
        }

        sqlite3_finalize(statement)
        return failedMessages
    }
    
    // MARK: - Fetch Unread Messages
    func fetchUnreadMessages(conversationId: String) {
        let query = "SELECT * FROM Messages WHERE isRead = 0;"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                if let message = parseMessageRow(statement: statement) {
                    LoggerService.shared.log(.info, "Unread message: \(message.text)", category: LogCategory.sqliteMessages)
                }
            }
        } else {
            LoggerService.shared.log(.error, "Failed to prepare fetchUnreadMessages query.", category: LogCategory.sqliteMessages)
        }

        sqlite3_finalize(statement)
    }
    
    // MARK: - Mark Message As Read
    func markMessageAsReadLocally(messageId: String) {
        let updateQuery = "UPDATE Messages SET isRead = 1 WHERE id = ?;"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, updateQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (messageId as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) != SQLITE_DONE {
                LoggerService.shared.log(.error, "Failed to mark message as read: \(messageId)", category: LogCategory.sqliteMessages)
            }
        } else {
            LoggerService.shared.log(.error, "Failed to prepare update statement for marking message as read.", category: LogCategory.sqliteMessages)
        }

        sqlite3_finalize(statement)
    }
    
    // Helper to parse a row into a MessagesModel
    private func parseMessageRow(statement: OpaquePointer?) -> MessagesModel? {
        guard let statement = statement else {
            LoggerService.shared.log(.error, "SQLite statement pointer is nil in parseMessageRow", category: LogCategory.sqliteMessages)
            return nil
            }
        guard
            let idCStr = sqlite3_column_text(statement, 0),
            let senderIdCStr = sqlite3_column_text(statement, 1),
            let textCStr = sqlite3_column_text(statement, 2),
            let typeCStr = sqlite3_column_text(statement, 5),
            let statusCStr = sqlite3_column_text(statement, 7)
        else {
            LoggerService.shared.log(.warning, "Failed to parse some columns in parseMessageRow", category: LogCategory.sqliteMessages)
            return nil
        }
        let id = String(cString: idCStr)
        let senderId = String(cString: senderIdCStr)
        let text = String(cString: textCStr)
        let sentAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 3))
        let isRead = sqlite3_column_int(statement, 4) == 1
        let type = MessageType(rawValue: String(cString: typeCStr)) ?? .text
        let isSynced = sqlite3_column_int(statement, 6) == 1
        let status = MessageStatus(rawValue: String(cString: statusCStr)) ?? .pending

        return MessagesModel(
            id: id,
            senderId: senderId,
            text: text,
            sentAt: sentAt,
            isRead: isRead,
            type: type,
            isSynced: isSynced,
            status: status
        )
    }


    
    
    // MARK:  - Calendar Specific -
    // MARK: - Create Calendar Table
    private func createMyCalendarTable() {
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS MyCalendar (
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            meetingIds TEXT,
            isSynced BOOLEAN
        );
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, createTableQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "MyCalendar table created successfully.", category: LogCategory.sqliteCalendar)
            } else {
                LoggerService.shared.log(.error, "Failed to create MyCalendar table.", category: LogCategory.sqliteCalendar)
            }
        } else {
            LoggerService.shared.log(.error, "Error preparing CREATE TABLE statement for MyCalendar.", category: LogCategory.sqliteCalendar)
        }
        
        sqlite3_finalize(statement)
    }
    
    // MARK: - Clear Local Calendar Cache
    /// Deletes all locally cached calendar events from SQLite.
    /// Called during logout to:
    /// - Protect user privacy
    /// - Prevent showing outdated calendar entries
    /// - Ensure a clean sync after login
    func clearLocalCalendarCache() {
        let deleteQuery = "DELETE FROM MyCalendar;"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "Local calendar cache cleared successfully.", category: LogCategory.sqliteCalendar)
            } else {
                LoggerService.shared.log(.error, "Failed to clear local calendar cache.", category: LogCategory.sqliteCalendar)
            }
        } else {
            LoggerService.shared.log(.error, "Failed to prepare delete statement for calendar cache.", category: LogCategory.sqliteCalendar)
        }

        sqlite3_finalize(statement)
    }

        
    // MARK: - Fetch MyCalendar
    func fetchMyCalendar(userId: String) -> MyCalendar? {
        let query = "SELECT * FROM MyCalendar WHERE userId = ? LIMIT 1;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (userId as NSString).utf8String, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let userId = String(cString: sqlite3_column_text(statement, 1))
                let meetingIdsString = sqlite3_column_text(statement, 2).map { String(cString: $0) } ?? ""
                
                let meetingIds = meetingIdsString.isEmpty ? [] : meetingIdsString.components(separatedBy: ",")
                LoggerService.shared.log(.info, "Fetched calendar for user \(userId)", category: LogCategory.sqliteCalendar)
                sqlite3_finalize(statement)
                
                return MyCalendar(id: id, userId: userId, meetingIds: meetingIds)
            } else {
                LoggerService.shared.log(.warning, "No calendar found for user \(userId)", category: LogCategory.sqliteCalendar)
            }
        } else {
            LoggerService.shared.log(.error, "Failed to prepare fetch statement for user \(userId)", category: LogCategory.sqliteCalendar)
        }
        
        sqlite3_finalize(statement)
        return nil
    }
        
    // MARK: - Update MyCalendar
    func updateMyCalendar(calendar: MyCalendar) {
        let updateQuery = "UPDATE MyCalendar SET meetingIds = ? WHERE id = ?;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, updateQuery, -1, &statement, nil) == SQLITE_OK {
            let meetingIdsString = calendar.meetingIds.joined(separator: ",")
            
            sqlite3_bind_text(statement, 1, (meetingIdsString as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (calendar.id as NSString).utf8String, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "MyCalendar updated successfully for id: \(calendar.id)", category: LogCategory.sqliteCalendar)
            } else {
                LoggerService.shared.log(.error, "Failed to update MyCalendar for id: \(calendar.id)", category: LogCategory.sqliteCalendar)
            }
        } else {
            LoggerService.shared.log(.error, "Failed to prepare update statement for MyCalendar id: \(calendar.id)", category: LogCategory.sqliteCalendar)
        }
        
        sqlite3_finalize(statement)
    }
    
    // MARK: - Cache Calendar (Insert if new, update if existing)
    func cacheCalendar(calendar: MyCalendar) {
        if fetchMyCalendar(userId: calendar.userId) == nil {
            let insertQuery = "INSERT INTO MyCalendar (id, userId, meetingIds, isSynced) VALUES (?, ?, ?, ?);"
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
                let meetingIdsString = calendar.meetingIds.joined(separator: ",")
                
                sqlite3_bind_text(statement, 1, (calendar.id as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 2, (calendar.userId as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 3, (meetingIdsString as NSString).utf8String, -1, nil)
                
                if sqlite3_step(statement) == SQLITE_DONE {
                    LoggerService.shared.log(.info, "MyCalendar cached successfully for id: \(calendar.id)", category: LogCategory.sqliteCalendar)
                } else {
                    LoggerService.shared.log(.error, "Failed to cache MyCalendar for id: \(calendar.id)", category: LogCategory.sqliteCalendar)
                }
            } else {
                LoggerService.shared.log(.error, "Failed to prepare insert statement for MyCalendar id: \(calendar.id)", category: LogCategory.sqliteCalendar)
            }
            
            sqlite3_finalize(statement)
        } else {
            updateMyCalendar(calendar: calendar)
        }
    }
    
    // MARK: - Profile Specific -
    // MARK: - Creates a Profiles Table
    private func createProfileTable() {
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS Profiles (
            id TEXT PRIMARY KEY,
            firstName TEXT,
            lastName TEXT,
            email TEXT,
            region TEXT,
            country TEXT,
            nativeLanguage TEXT,
            targetLanguage TEXT,
            targetLanguageProficiency TEXT,
            goals BLOB,
            hobbies BLOB,
            profileImageURL TEXT,
            createdAt DOUBLE,
            updatedAt DOUBLE,
            isSynced INTEGER
        );
        """

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "Profiles table created successfully.", category: LogCategory.sqliteProfile)
            } else {
                LoggerService.shared.log(.error, "Failed to execute Profiles table creation step.", category: LogCategory.sqliteProfile)
            }
        } else {
            LoggerService.shared.log(.error, "Failed to prepare Profiles table creation statement.", category: LogCategory.sqliteProfile)
        }
        sqlite3_finalize(statement)
    }

    
    // MARK: - Clear Local Profiles Cache
    /// Deletes all locally cached user profiles from SQLite.
    /// Called during logout to:
    /// - Protect user privacy
    /// - Avoid stale profile data being shown under a new login
    func clearLocalProfilesCache() {
        let deleteQuery = "DELETE FROM Profiles;" // Adjust table name if different
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "Local profiles cache cleared successfully.", category: LogCategory.sqliteProfile)
            } else {
                LoggerService.shared.log(.error, "Failed to clear local profiles cache.", category: LogCategory.sqliteProfile)
            }
        } else {
            LoggerService.shared.log(.error, "Failed to prepare delete statement for profiles cache.", category: LogCategory.sqliteProfile)
        }

        sqlite3_finalize(statement)
    }

    
    func insertProfile(_ profile: Profile) {
        let insertQuery = """
        INSERT OR REPLACE INTO Profiles
        (id, firstName, lastName, email, region, country, nativeLanguage, targetLanguage, targetLanguageProficiency, goals, hobbies, profileImageURL, createdAt, updatedAt, isSynced)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """

        var statement: OpaquePointer?
        let data = profile.toSQLite()

        if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (data["id"] as! NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (data["firstName"] as! NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (data["lastName"] as! NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 4, (data["email"] as! NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 5, (data["region"] as! NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 6, (data["country"] as! NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 7, (data["nativeLanguage"] as! NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 8, (data["targetLanguage"] as! NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 9, (data["targetLanguageProficiency"] as! NSString).utf8String, -1, nil)

            let goalsData = data["goals"] as! Data
            let hobbiesData = data["hobbies"] as! Data
            sqlite3_bind_blob(statement, 10, (goalsData as NSData).bytes, Int32(goalsData.count), nil)
            sqlite3_bind_blob(statement, 11, (hobbiesData as NSData).bytes, Int32(hobbiesData.count), nil)

            sqlite3_bind_text(statement, 12, (data["profileImageURL"] as! NSString).utf8String, -1, nil)
            sqlite3_bind_double(statement, 13, data["createdAt"] as! Double)
            sqlite3_bind_double(statement, 14, data["updatedAt"] as! Double)
            sqlite3_bind_int(statement, 15, data["isSynced"] as! Bool ? 1 : 0)

            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "✅ Profile inserted successfully for \(profile.id)", category: LogCategory.sqliteProfile)
            } else {
                LoggerService.shared.log(.error, "❌ Failed to insert profile. Error: \(String(cString: sqlite3_errmsg(db)))", category: LogCategory.sqliteProfile)
            }
        } else {
            LoggerService.shared.log(.error, "❌ Failed to prepare insert statement. Error: \(String(cString: sqlite3_errmsg(db)))", category: LogCategory.sqliteProfile)
        }

        sqlite3_finalize(statement)
    }


    
    
    // MARK: - Fetch Profile by User ID
    func fetchProfile(for userId: String) -> Profile? {
        let query = "SELECT * FROM Profiles WHERE id = ?"
        var statement: OpaquePointer?
        var profile: Profile? = nil

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (userId as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let firstName = String(cString: sqlite3_column_text(statement, 1))
                let lastName = String(cString: sqlite3_column_text(statement, 2))
                let email = String(cString: sqlite3_column_text(statement, 3))
                let region = String(cString: sqlite3_column_text(statement, 4))
                let country = String(cString: sqlite3_column_text(statement, 5))
                let nativeLanguageRaw = String(cString: sqlite3_column_text(statement, 6))
                let targetLanguageRaw = String(cString: sqlite3_column_text(statement, 7))
                let targetLanguageProficiencyRaw = String(cString: sqlite3_column_text(statement, 8))

                // Decode BLOB data for goals
                let goalsData = sqlite3_column_blob(statement, 9)
                let goalsLength = sqlite3_column_bytes(statement, 9)
                let goals: [String] = {
                    if let goalsData = goalsData {
                        let data = Data(bytes: goalsData, count: Int(goalsLength))
                        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
                    }
                    return []
                }()

                // Decode BLOB data for hobbies
                let hobbiesData = sqlite3_column_blob(statement, 10)
                let hobbiesLength = sqlite3_column_bytes(statement, 10)
                let hobbies: [Hobbies] = {
                    if let hobbiesData = hobbiesData {
                        let data = Data(bytes: hobbiesData, count: Int(hobbiesLength))
                        let rawValues = (try? JSONDecoder().decode([String].self, from: data)) ?? []
                        return rawValues.compactMap { Hobbies(rawValue: $0) }
                    }
                    return []
                }()

                let profileImageURL = String(cString: sqlite3_column_text(statement, 11))
                let createdAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 12))
                let updatedAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 13))
                let isSynced = sqlite3_column_int(statement, 14) != 0

                profile = Profile(
                    id: id,
                    firstName: firstName,
                    lastName: lastName,
                    email: email,
                    region: region,
                    country: country,
                    nativeLanguage: Language(rawValue: nativeLanguageRaw) ?? .english,
                    targetLanguage: Language(rawValue: targetLanguageRaw) ?? .english,
                    targetLanguageProficiency: LanguageProficiency(rawValue: targetLanguageProficiencyRaw) ?? .beginner,
                    goals: goals,
                    hobbies: hobbies,
                    profileImageURL: profileImageURL,
                    createdAt: createdAt,
                    updatedAt: updatedAt,
                    isSynced: isSynced
                )
                LoggerService.shared.log(.info, "✅ Fetched profile for \(userId)", category: LogCategory.sqliteProfile)

            }
        } else {
            LoggerService.shared.log(.error, "❌ Failed to prepare fetch statement. Error: \(String(cString: sqlite3_errmsg(db)))", category: LogCategory.sqliteProfile)
        }

        sqlite3_finalize(statement)
        return profile
    }

    
    // MARK: - Update Profile in SQLite
    func updateProfile(_ profile: Profile) {
        let updateQuery = """
        UPDATE Profiles SET
            firstName = ?, lastName = ?, email = ?, region = ?, country = ?,
            nativeLanguage = ?, targetLanguage = ?, targetLanguageProficiency = ?,
            goals = ?, hobbies = ?, profileImageURL = ?, updatedAt = ?, isSynced = ?
        WHERE id = ?;
        """

        var statement: OpaquePointer?
        let data = profile.toSQLiteData()  // Make sure this returns a [String: Any] matching the new model

        if sqlite3_prepare_v2(db, updateQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (data["firstName"] as! NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (data["lastName"] as! NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (data["email"] as! NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 4, (data["region"] as! NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 5, (data["country"] as! NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 6, (data["nativeLanguage"] as! NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 7, (data["targetLanguage"] as! NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 8, (data["targetLanguageProficiency"] as! NSString).utf8String, -1, nil)

            // goals (BLOB)
            let goalsData = data["goals"] as! Data
            sqlite3_bind_blob(statement, 9, (goalsData as NSData).bytes, Int32(goalsData.count), nil)

            // hobbies (BLOB)
            let hobbiesData = data["hobbies"] as! Data
            sqlite3_bind_blob(statement, 10, (hobbiesData as NSData).bytes, Int32(hobbiesData.count), nil)

            sqlite3_bind_text(statement, 11, (data["profileImageURL"] as! NSString).utf8String, -1, nil)
            sqlite3_bind_double(statement, 12, data["updatedAt"] as! Double)
            sqlite3_bind_int(statement, 13, (data["isSynced"] as! Bool) ? 1 : 0)

            // WHERE id = ?
            sqlite3_bind_text(statement, 14, (data["id"] as! NSString).utf8String, -1, nil)

            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "✅ Profile updated successfully for \(profile.id)", category: LogCategory.sqliteProfile)
            } else {
                LoggerService.shared.log(.error, "❌ Failed to update profile. Error: \(String(cString: sqlite3_errmsg(db)))", category: LogCategory.sqliteProfile)
            }
        } else {
            LoggerService.shared.log(.error, "❌ Failed to prepare update statement. Error: \(String(cString: sqlite3_errmsg(db)))", category: LogCategory.sqliteProfile)
        }

        sqlite3_finalize(statement)
    }
    
    // MARK: - Check If Profile Exists
    func profileExists(for userId: String) -> Bool {
        let query = "SELECT 1 FROM Profiles WHERE id = ? LIMIT 1;"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (userId as NSString).utf8String, -1, nil)
            if sqlite3_step(statement) == SQLITE_ROW {
                sqlite3_finalize(statement)
                LoggerService.shared.log(.info, "✅ Profile exists for \(userId)", category: LogCategory.sqliteProfile)
                return true
            }
        } else {
            LoggerService.shared.log(.error, "❌ Failed to prepare profileExists statement. Error: \(String(cString: sqlite3_errmsg(db)))", category: LogCategory.sqliteProfile)
        }

        sqlite3_finalize(statement)
        return false
    }
    
    
    // MARK: - Update Sync Status Of Profile
    func updateSyncStatus(for userId: String, isSynced: Bool) {
        let query = "UPDATE Profiles SET isSynced = ? WHERE id = ?;"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, isSynced ? 1 : 0)
            sqlite3_bind_text(statement, 2, (userId as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) != SQLITE_DONE {
                LoggerService.shared.log(.error, "❌ Failed to update sync status for \(userId)", category: LogCategory.sqliteProfile)
            } else {
                LoggerService.shared.log(.error, "❌ Failed to prepare sync status update for \(userId)", category: LogCategory.sqliteProfile)
            }
        }

        sqlite3_finalize(statement)
    }
    
    // MARK: - Upsert Profile
    func upsertProfile(_ profile: Profile) {
        if profileExists(for: profile.id) {
            updateProfile(profile)  // existing update function
        } else {
            insertProfile(profile)  // existing insert function
        }
    }
    
    // MARK: - Clear Profile
    /// Deletes the cached profile for the specified userId from the SQLite database.
    /// Typically used when logging out or resetting the user data locally.
    func clearProfile(for userId: String) {
        let deleteSQL = "DELETE FROM Profiles WHERE id = ?;"
        var statement: OpaquePointer?

        // Prepare the SQL statement
        if sqlite3_prepare_v2(db, deleteSQL, -1, &statement, nil) == SQLITE_OK {
            // Bind the userId parameter
            sqlite3_bind_text(statement, 1, (userId as NSString).utf8String, -1, nil)

            // Execute the statement
            if sqlite3_step(statement) != SQLITE_DONE {
                LoggerService.shared.log(.error, "❌ Error deleting profile with userId \(userId)", category: LogCategory.sqliteProfile)
            }
        } else {
            LoggerService.shared.log(.error, "❌ Failed to prepare delete statement for userId \(userId)", category: LogCategory.sqliteProfile)
        }

        // Finalize the statement to release resources
        sqlite3_finalize(statement)
    }
    // MARK: - Refresh User Profile
    /// Forces a fresh fetch of the user's profile from Firestore,
    /// bypassing any cached data. Useful when the profile may have changed
    /// on the server (e.g., after another device updates it).
    /// - Parameter userId: The unique identifier of the user whose profile to fetch.
    func refreshUserProfile(userId: String) {
        fetchUserProfile(userId: userId)
    }

    // MARK: - Handle Errors Centrally
    /// Handles errors in a consistent way throughout the view model.
    /// Sets the loading state to false, updates the `errorMessage`,
    /// and prints the error to the console for debugging.
    /// - Parameter error: The error to handle.
    private func handleError(_ error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
            LoggerService.shared.log(.error, "Profile Error: \(error.localizedDescription)", category: LogCategory.sqliteProfile)
        }
    }

    // MARK: - Profile Validation
    /// Validates that the profile contains required fields before
    /// allowing it to be saved or updated. Add more checks here as needed.
    /// - Parameter profile: The profile to validate.
    /// - Returns: `true` if the profile is valid; `false` otherwise.
    func isValid(profile: Profile) -> Bool {
        return !profile.firstName.isEmpty && !profile.email.isEmpty
    }




    
    // MARK: - Delete Profile
    func deleteProfile(for userId: String) {
        let deleteQuery = "DELETE FROM Profiles WHERE id = ?;"
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (userId as NSString).utf8String, -1, nil)
            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "✅ Deleted profile \(userId)", category: LogCategory.sqliteProfile)
            } else {
                LoggerService.shared.log(.error, "❌ Failed to delete profile for userId \(userId)", category: LogCategory.sqliteProfile)
            }
        }
        sqlite3_finalize(statement)
    }


    // MARK: - Meeting Specific
    
    // MARK: -  Create Meetings Table
    private func createMeetingsTable() {
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS Meetings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            discussionTopics TEXT,  -- Store as JSON-encoded string
            datetime TEXT NOT NULL, -- Store in ISO-8601 format
            createdByProfileId TEXT NOT NULL,
            notes TEXT,
            meetinglink TEXT,
            passcode TEXT,
            participants TEXT,  -- Store as JSON-encoded string
            status TEXT NOT NULL
        );
        """
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "✅ Meetings table created successfully.", category: LogCategory.sqliteMeeting)
            } else {
                LoggerService.shared.log(.error, "❌ Failed to execute create table statement for Meetings.", category: LogCategory.sqliteMeeting)
            }
        } else {
            LoggerService.shared.log(.error, "❌ Error preparing create table statement for Meetings.", category: LogCategory.sqliteMeeting)
        }
        sqlite3_finalize(statement)
    }
    
    // MARK: - Clear Local Meetings Cache
    /// Deletes all locally cached meeting data from SQLite.
    /// Called during logout to:
    /// - Clear personal meeting records
    /// - Avoid data leak across users
    func clearLocalMeetingsCache() {
        let deleteQuery = "DELETE FROM Meetings;"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "✅ Local meetings cache cleared successfully.", category: LogCategory.sqliteMeeting)
            } else {
                LoggerService.shared.log(.error, "❌ Failed to clear local meetings cache.", category: LogCategory.sqliteMeeting)
            }
        } else {
            LoggerService.shared.log(.error, "❌ Failed to prepare delete statement for meetings cache.", category: LogCategory.sqliteMeeting)
        }

        sqlite3_finalize(statement)
    }


    // MARK: - Cache Meetings
    func cacheMeetings(_ meetings: [MeetingModel]) {
        let insertQuery = """
        INSERT INTO Meetings (title, description, discussionTopics, datetime, createdByProfileId, notes, meetinglink, passcode, participants, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        
        sqlite3_exec(db, "BEGIN TRANSACTION", nil, nil, nil)  // Start transaction

        for meeting in meetings {
            if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
                // Encode discussionTopics and participants to JSON strings
                let discussionTopicsJSON = try? JSONEncoder().encode(meeting.discussionTopics)
                let participantsJSON = try? JSONEncoder().encode(meeting.participants)
                
                // Bind the encoded JSON strings
                sqlite3_bind_text(statement, 1, (meeting.title as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 2, (meeting.description ?? "" as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 3, discussionTopicsJSON.map { String(data: $0, encoding: .utf8) } ?? "{}", -1, nil)
                sqlite3_bind_text(statement, 4, meeting.datetime, -1, nil)
                sqlite3_bind_text(statement, 5, (meeting.createdByProfileId as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 6, (meeting.notes as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 7, (meeting.meetinglink as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 8, (meeting.passcode as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 9, participantsJSON.map { String(data: $0, encoding: .utf8) } ?? "[]", -1, nil)
                sqlite3_bind_text(statement, 10, (meeting.status as NSString).utf8String, -1, nil)
                
                if sqlite3_step(statement) != SQLITE_DONE {
                    LoggerService.shared.log(.error, "❌ Failed to insert meeting titled '\(meeting.title)'", category: LogCategory.sqliteMeeting)
                } else {
                    LoggerService.shared.log(.info, "✅ Inserted meeting titled '\(meeting.title)' successfully.", category: LogCategory.sqliteMeeting)
                } catch {
                    LoggerService.shared.log(.error, "❌ JSON encoding error for meeting titled '\(meeting.title)': \(error.localizedDescription)", category: LogCategory.sqliteMeeting)
                }
                sqlite3_reset(statement)
            } else {
                LoggerService.shared.log(.error, "❌ Failed to prepare insert statement for meeting titled '\(meeting.title)'", category: LogCategory.sqliteMeeting)
            }
        }
        sqlite3_exec(db, "COMMIT TRANSACTION", nil, nil, nil)  // Commit transaction
        sqlite3_finalize(statement)

    }

    // MARK: - Insert Meetings Table
    func insertMeeting(_ meeting: MeetingModel) {
        let insertQuery = """
        INSERT INTO Meetings (id, title, description, discussionTopics, datetime, createdByProfileId, notes, meetinglink, passcode, participants, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        
        // Encode discussionTopics and participants to JSON strings
        let discussionTopicsJSON = try? JSONEncoder().encode(meeting.discussionTopics)
        let participantsJSON = try? JSONEncoder().encode(meeting.participants)

        if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (meeting.id as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (meeting.title as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, discussionTopicsJSON.map { String(data: $0, encoding: .utf8) } ?? "{}", -1, nil)
            sqlite3_bind_text(statement, 4, meeting.datetime, -1, nil)
            sqlite3_bind_text(statement, 5, (meeting.createdByProfileId as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 6, (meeting.notes as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 7, (meeting.meetinglink as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 8, (meeting.passcode as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 9, participantsJSON.map { String(data: $0, encoding: .utf8) } ?? "[]", -1, nil)
            sqlite3_bind_text(statement, 10, (meeting.status as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "✅ Meeting inserted successfully with id: \(meeting.id)", category: LogCategory.sqliteMeeting)
            } else {
                LoggerService.shared.log(.error, "❌ Error inserting meeting with id: \(meeting.id)", category: LogCategory.sqliteMeeting)
            }
        } else {
            LoggerService.shared.log(.error, "❌ Failed to prepare insert statement for meeting with id: \(meeting.id)", category: LogCategory.sqliteMeeting)
        }
        sqlite3_finalize(statement)
    }

    // MARK: - Fetch Meetings Table
    func fetchMeetings() -> [MeetingModel] {
        let query = "SELECT * FROM Meetings;"
        var statement: OpaquePointer?
        var meetings: [MeetingModel] = []

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let title = String(cString: sqlite3_column_text(statement, 1))
                let description = String(cString: sqlite3_column_text(statement, 2))
                
                // Decode JSON strings
                let discussionTopicsData = String(cString: sqlite3_column_text(statement, 3)).data(using: .utf8)
                let discussionTopics = (try? JSONDecoder().decode([String: [String]].self, from: discussionTopicsData ?? Data())) ?? [:]

                let datetime = String(cString: sqlite3_column_text(statement, 4))
                let createdByProfileId = String(cString: sqlite3_column_text(statement, 5))
                let notes = String(cString: sqlite3_column_text(statement, 6))
                let meetinglink = String(cString: sqlite3_column_text(statement, 7))
                let passcode = String(cString: sqlite3_column_text(statement, 8))

                // Decode participants from JSON string
                let participantsData = String(cString: sqlite3_column_text(statement, 9)).data(using: .utf8)
                let participants = (try? JSONDecoder().decode([String].self, from: participantsData ?? Data())) ?? []

                let status = String(cString: sqlite3_column_text(statement, 10))

                let meeting = MeetingModel(id: id, title: title, description: description, discussionTopics: discussionTopics, datetime: datetime, createdByProfileId: createdByProfileId, notes: notes, meetinglink: meetinglink, passcode: passcode, participants: participants, status: status)

                meetings.append(meeting)
            }
            LoggerService.shared.log(.info, "✅ Fetched \(meetings.count) meetings from SQLite.", category: LogCategory.sqliteMeeting)

        } else {
            LoggerService.shared.log(.error, "❌ Failed to prepare fetch statement for Meetings.", category: LogCategory.sqliteMeeting)
        }
        sqlite3_finalize(statement)
        return meetings
    }

    // MARK: -  Update Meetings Table
    func updateMeeting(_ meeting: MeetingModel) {
        let updateQuery = """
        UPDATE Meetings
        SET title = ?, description = ?, discussionTopics = ?, datetime = ?, createdByProfileId = ?, notes = ?, meetinglink = ?, passcode = ?, participants = ?, status = ?
        WHERE id = ?;
        """

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, updateQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (meeting.title as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (meeting.description as NSString).utf8String, -1, nil)
            
            let discussionTopicsJSON = try? JSONEncoder().encode(meeting.discussionTopics)
            let participantsJSON = try? JSONEncoder().encode(meeting.participants)

            sqlite3_bind_text(statement, 3, discussionTopicsJSON.map { String(data: $0, encoding: .utf8) } ?? "{}", -1, nil)
            sqlite3_bind_text(statement, 4, (meeting.datetime as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 5, (meeting.createdByProfileId as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 6, (meeting.notes as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 7, (meeting.meetinglink as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 8, (meeting.passcode as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 9, (participantsJSON?.base64EncodedString() as NSString?)?.utf8String, -1, nil)
            sqlite3_bind_text(statement, 10, (meeting.status as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 11, (meeting.id as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "✅ Meeting updated successfully: \(meeting.id)", category: LogCategory.sqliteMeeting)
            } else {
                LoggerService.shared.log(.error, "❌ Failed to update meeting: \(meeting.id)", category: LogCategory.sqliteMeeting)
            }
        } else {
            LoggerService.shared.log(.error, "❌ Failed to prepare update statement for meeting: \(meeting.id)", category: LogCategory.sqliteMeeting)
        }
        sqlite3_finalize(statement)
    }
    
    // MARK: - Update Meeting Status 
    func updateMeetingStatus(meetingId: String, status: String) {
        let updateQuery = """
        UPDATE Meetings
        SET status = ?
        WHERE id = ?;
        """

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, updateQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (status as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (meetingId as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "✅ Meeting status updated successfully for id: \(meetingId)", category: LogCategory.sqliteMeeting)
            } else {
                LoggerService.shared.log(.error, "❌ Failed to update meeting status for id: \(meetingId)", category: LogCategory.sqliteMeeting)
            }
        } else {
            LoggerService.shared.log(.error, "❌ Failed to prepare update statement for meeting status id: \(meetingId)", category: LogCategory.sqliteMeeting)
        }

        sqlite3_finalize(statement)
    }


    // MARK: -  Delete Meetings Table
    func deleteMeeting(_ meetingID: String) {
        let deleteQuery = "DELETE FROM Meetings WHERE id = ?;"
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (meetingID as NSString).utf8String, -1, nil)
            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "✅ Deleted meeting with id: \(meetingID)", category: LogCategory.sqliteMeeting)
            } else {
                LoggerService.shared.log(.error, "❌ Failed to delete meeting with id: \(meetingID)", category: LogCategory.sqliteMeeting)
            }
        } else {
            LoggerService.shared.log(.error, "❌ Failed to prepare delete statement for meeting id: \(meetingID)", category: LogCategory.sqliteMeeting)
        }
        sqlite3_finalize(statement)
    }

    
    // MARK: - VOCAB CARD SPECIFIC -
    
    //MARK: - Create Vocab Card Table
    private func createVocabCardTable() {
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS VocabCard (
            id TEXT PRIMARY KEY,
            sheetId TEXT NOT NULL,
            front TEXT,
            back TEXT,
            addedBy TEXT NOT NULL,
            favorited INTEGER NOT NULL DEFAULT 0,
            createdAt REAL NOT NULL,
            updatedAt REAL NOT NULL,
            lastReviewed REAL,
            isSynced INTEGER NOT NULL DEFAULT 0
        );
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "✅ VocabCard table created successfully.", category: .LogCategory.sqliteVocabCard)
            } else {
                LoggerService.shared.log(.error, "❌ Failed to execute create table step for VocabCard.", category: .LogCategory.sqliteVocabCard)
            }
        } else {
            LoggerService.shared.log(.error, "❌ Failed to prepare create table statement for VocabCard.", category: .LogCategory.sqliteVocabCard)
        }
        sqlite3_finalize(statement)
    }
    
    // MARK: - Clear Local Vocab Cards Cache
    /// Deletes all locally cached vocab cards from SQLite.
    /// Called during logout to:
    /// - Ensure vocab cards do not persist across users
    /// - Clear out stale or orphaned data
    func clearLocalVocabCardsCache() {
        let deleteQuery = "DELETE FROM VocabCard;"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "✅ Local vocab cards cache cleared successfully.", category: .LogCategory.sqliteVocabCard)
            } else {
                LoggerService.shared.log(.error, "❌ Failed to clear local vocab cards cache.", category: .LogCategory.sqliteVocabCard)
            }
        } else {
            LoggerService.shared.log(.error, "❌ Failed to prepare delete statement for vocab cards cache.", category: .LogCategory.sqliteVocabCard)
        }

        sqlite3_finalize(statement)
    }


    
    // MARK: - Create Vocab Card
    func createVocabCard(vocabCard: VocabCardModel) {
        let insertQuery = """
            INSERT INTO VocabCard (id, sheetId, front, back, addedBy, favorited, createdAt, updatedAt, lastReviewed, isSynced) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (vocabCard.id as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (vocabCard.sheetId as NSString).utf8String, -1, nil) // Added sheetId binding
            sqlite3_bind_text(statement, 3, (vocabCard.front as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 4, (vocabCard.back as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 5, (vocabCard.addedBy as NSString).utf8String, -1, nil)
            sqlite3_bind_int(statement, 6, vocabCard.favorited ? 1 : 0)
            sqlite3_bind_double(statement, 7, vocabCard.createdAt.timeIntervalSince1970)
            sqlite3_bind_double(statement, 8, vocabCard.updatedAt.timeIntervalSince1970)

            if let lastReviewed = vocabCard.lastReviewed {
                sqlite3_bind_double(statement, 9, lastReviewed.timeIntervalSince1970)
            } else {
                sqlite3_bind_null(statement, 9)
            }

            sqlite3_bind_int(statement, 10, vocabCard.isSynced ? 1 : 0)

            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "✅ Vocab card created successfully for id: \(vocabCard.id).", category: .LogCategory.sqliteVocabCard)
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                LoggerService.shared.log(.error, "❌ Error creating vocab card \(vocabCard.id): \(errorMessage)", category: .LogCategory.sqliteVocabCard)
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            LoggerService.shared.log(.error, "❌ Error preparing insert statement for vocab card \(vocabCard.id): \(errorMessage)", category: .LogCategory.sqliteVocabCard)
        }

        sqlite3_finalize(statement)
    }


    // MARK: - Cache Vocab Cards to the SQLite database
    func cacheVocabCards(_ vocabCards: [VocabCardModel]) {
        let insertQuery = """
            INSERT INTO VocabCard (id, sheetId, front, back, addedBy, favorited, createdAt, updatedAt, lastReviewed, isSynced) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """

        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
            for vocabCard in vocabCards {
                sqlite3_bind_text(statement, 1, (vocabCard.id as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 2, (vocabCard.sheetId as NSString).utf8String, -1, nil) // Added sheetId binding
                sqlite3_bind_text(statement, 3, (vocabCard.front as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 4, (vocabCard.back as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 5, (vocabCard.addedBy as NSString).utf8String, -1, nil)
                sqlite3_bind_int(statement, 6, vocabCard.favorited ? 1 : 0)
                sqlite3_bind_double(statement, 7, vocabCard.createdAt.timeIntervalSince1970)
                sqlite3_bind_double(statement, 8, vocabCard.updatedAt.timeIntervalSince1970)

                if let lastReviewed = vocabCard.lastReviewed {
                    sqlite3_bind_double(statement, 9, lastReviewed.timeIntervalSince1970)
                } else {
                    sqlite3_bind_null(statement, 9)
                }

                sqlite3_bind_int(statement, 10, vocabCard.isSynced ? 1 : 0)

                if sqlite3_step(statement) == SQLITE_DONE {
                    LoggerService.shared.log(.info, "✅ Vocab card cached successfully: \(vocabCard.front)", category: .LogCategory.sqliteVocabCard)
                } else {
                    let errorMessage = String(cString: sqlite3_errmsg(db))
                    LoggerService.shared.log(.error, "❌ Failed to cache vocab card (\(vocabCard.front)): \(errorMessage)", category: .LogCategory.sqliteVocabCard)
                }

                sqlite3_reset(statement)
                sqlite3_clear_bindings(statement)
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            LoggerService.shared.log(.error, "❌ Error preparing insert statement for vocab cards: \(errorMessage)", category: .LogCategory.sqliteVocabCard)
        }

        sqlite3_finalize(statement)
    }



    // MARK: - Fetch Vocab Card
    func fetchVocabCard(sheetId: String, id: String) -> VocabCardModel? {
        let selectQuery = "SELECT * FROM VocabCard WHERE sheetId = ? AND id = ?;"
        var statement: OpaquePointer?
        var vocabCard: VocabCardModel? = nil
        
        if sqlite3_prepare_v2(db, selectQuery, -1, &statement, nil) == SQLITE_OK {
            // Bind sheetId and id to the query
            sqlite3_bind_text(statement, 1, (sheetId as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (id as NSString).utf8String, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_ROW {
                let vocabCardId = String(cString: sqlite3_column_text(statement, 0))
                let vocabCardSheetId = String(cString: sqlite3_column_text(statement, 1))  // Assuming sheetId is stored in column 1
                let vocabCardFront = String(cString: sqlite3_column_text(statement, 2))
                let vocabCardBack = String(cString: sqlite3_column_text(statement, 3))
                let vocabCardAddedBy = String(cString: sqlite3_column_text(statement, 4))
                let vocabCardFavorited = sqlite3_column_int(statement, 5) == 1
                let vocabCardCreatedAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 6))
                let vocabCardUpdatedAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 7))
                let vocabCardLastReviewed = sqlite3_column_type(statement, 8) == SQLITE_NULL ? nil : Date(timeIntervalSince1970: sqlite3_column_double(statement, 8))
                let vocabCardIsSynced = sqlite3_column_int(statement, 9) == 1
                
                vocabCard = VocabCardModel(
                    id: vocabCardId,
                    sheetId: vocabCardSheetId,  // Added sheetId field to the model
                    front: vocabCardFront,
                    back: vocabCardBack,
                    addedBy: vocabCardAddedBy,
                    favorited: vocabCardFavorited,
                    createdAt: vocabCardCreatedAt,
                    updatedAt: vocabCardUpdatedAt,
                    lastReviewed: vocabCardLastReviewed,
                    isSynced: vocabCardIsSynced
                )
            } else {
                LoggerService.shared.log(.info, "No vocab card found with sheetId: \(sheetId) and id: \(id)", category: .LogCategory.sqliteVocabCard)
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            LoggerService.shared.log(.error, "Error preparing select statement: \(errorMessage)", category: .LogCategory.sqliteVocabCard)
        }

        sqlite3_finalize(statement)
        return vocabCard
    }



    // MARK: - Update Vocab Card
    func updateVocabCard(vocabCard: VocabCardModel) {
        let updateQuery = """
            UPDATE VocabCard 
            SET front = ?, back = ?, addedBy = ?, favorited = ?, updatedAt = ?, lastReviewed = ?, isSynced = ?
            WHERE id = ?;
        """
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, updateQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (vocabCard.front as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (vocabCard.back as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (vocabCard.addedBy as NSString).utf8String, -1, nil)
            sqlite3_bind_int(statement, 4, vocabCard.favorited ? 1 : 0)
            sqlite3_bind_double(statement, 5, vocabCard.updatedAt.timeIntervalSince1970)
            
            if let lastReviewed = vocabCard.lastReviewed {
                sqlite3_bind_double(statement, 6, lastReviewed.timeIntervalSince1970)
            } else {
                sqlite3_bind_null(statement, 6)
            }
            
            sqlite3_bind_int(statement, 7, vocabCard.isSynced ? 1 : 0)
            sqlite3_bind_text(statement, 8, (vocabCard.id as NSString).utf8String, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "✅ Vocab card updated successfully: \(vocabCard.front)", category: .LogCategory.sqliteVocabCard)
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                LoggerService.shared.log(.error, "❌ Error updating vocab card: \(errorMessage)", category: .LogCategory.sqliteVocabCard)
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            LoggerService.shared.log(.error, "❌ Error preparing update statement: \(errorMessage)", category: .LogCategory.sqliteVocabCard)
        }
        
        sqlite3_finalize(statement)
    }

    // MARK: - Delete Vocab Card
    func deleteVocabCard(_ id: String) {
        let deleteQuery = "DELETE FROM VocabCard WHERE id = ?;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (id as NSString).utf8String, -1, nil)
            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "✅ Vocab card deleted successfully (id: \(id)).", category: LogCategory.sqliteVocabCard)
            } else {
                LoggerService.shared.log(.error, "❌ Error deleting vocab card (id: \(id)).", category: LogCategory.sqliteVocabCard)
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            LoggerService.shared.log(.error, "❌ Error preparing delete statement for vocab card (id: \(id)) — \(errorMessage)", category: LogCategory.sqliteVocabCard)
        }
        
        sqlite3_finalize(statement)
    }
    
    // MARK: - Vocab Sheet Specific
    
    // MARK: - Create Vocab Sheet Table
    private func createVocabSheetTable() {
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS VocabSheet (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            createdBy TEXT NOT NULL,
            totalCards INTEGER NOT NULL,
            lastReviewed REAL,
            lastUpdated REAL NOT NULL,
            createdAt REAL NOT NULL,
            isSynced INTEGER NOT NULL DEFAULT 0
        );
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "✅ VocabSheet table created successfully.", category: LogCategory.sqliteVocabSheet)
            } else {
                LoggerService.shared.log(.error, "❌ Failed to execute VocabSheet table creation.", category: LogCategory.sqliteVocabSheet)
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            LoggerService.shared.log(.error, "❌ Error preparing VocabSheet table creation: \(errorMessage)", category: LogCategory.sqliteVocabSheet)
        }
        sqlite3_finalize(statement)
    }
    
    // MARK: - Clear Local Vocab Sheets Cache
    /// Deletes all locally cached vocab sheets from SQLite.
    /// Called during logout to:
    /// - Prevent access to another user’s vocab work
    /// - Remove stale data
    /// - Maintain user session integrity
    func clearLocalVocabSheetsCache() {
        let deleteQuery = "DELETE FROM VocabSheet;"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "✅ Local vocab sheet cache cleared successfully.", category: LogCategory.sqliteVocabSheet)
            } else {
                LoggerService.shared.log(.error, "❌ Failed to clear local vocab sheet cache.", category: LogCategory.sqliteVocabSheet)
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            LoggerService.shared.log(.error, "❌ Failed to prepare delete statement for vocab sheet cache: \(errorMessage)", category: LogCategory.sqliteVocabSheet)
        }

        sqlite3_finalize(statement)
    }


    // MARK: - Create Vocab Sheet
    func createVocabSheet(vocabSheet: VocabSheetModel) {
        let insertQuery = """
            INSERT INTO VocabSheet (id, name, createdBy, totalCards, lastReviewed, lastUpdated, createdAt, isSynced) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        """
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (vocabSheet.id as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (vocabSheet.name as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (vocabSheet.createdBy as NSString).utf8String, -1, nil)
            sqlite3_bind_int(statement, 4, Int32(vocabSheet.totalCards))
            sqlite3_bind_double(statement, 5, vocabSheet.lastReviewed?.timeIntervalSince1970 ?? 0)
            sqlite3_bind_double(statement, 6, vocabSheet.lastUpdated.timeIntervalSince1970)
            sqlite3_bind_double(statement, 7, vocabSheet.createdAt.timeIntervalSince1970)
            sqlite3_bind_int(statement, 8, vocabSheet.isSynced ? 1 : 0)  // Store as 1 (true) or 0 (false)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "✅ Vocab sheet created successfully: \(vocabSheet.name)", category: LogCategory.sqliteVocabSheet)
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                LoggerService.shared.log(.error, "❌ Error creating vocab sheet: \(errorMessage)", category: LogCategory.sqliteVocabSheet)
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            LoggerService.shared.log(.error, "❌ Error preparing insert statement for vocab sheet: \(errorMessage)", category: LogCategory.sqliteVocabSheet)
        }
        
        sqlite3_finalize(statement)
    }

    // MARK: - Fetch Vocab Sheet
    func fetchVocabSheet(id: String) -> VocabSheetModel? {
        let selectQuery = "SELECT * FROM VocabSheet WHERE id = ?;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, selectQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (id as NSString).utf8String, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_ROW {
                let vocabSheetId = String(cString: sqlite3_column_text(statement, 0))
                let vocabSheetName = String(cString: sqlite3_column_text(statement, 1))
                let vocabSheetCreatedBy = String(cString: sqlite3_column_text(statement, 2))
                let vocabSheetTotalCards = sqlite3_column_int(statement, 3)
                let vocabSheetLastReviewed = sqlite3_column_type(statement, 4) == SQLITE_NULL ? nil : Date(timeIntervalSince1970: sqlite3_column_double(statement, 4))
                let vocabSheetLastUpdated = Date(timeIntervalSince1970: sqlite3_column_double(statement, 5))
                let vocabSheetCreatedAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 6))
                let vocabSheetIsSynced = sqlite3_column_int(statement, 7) == 1
                
                sqlite3_finalize(statement)
                LoggerService.shared.log(.info, "✅ Vocab sheet fetched successfully: \(vocabSheetName)", category: LogCategory.sqliteVocabSheet)
                return VocabSheetModel(
                    id: vocabSheetId,
                    name: vocabSheetName,
                    cards: [], // Load separately
                    createdBy: vocabSheetCreatedBy,
                    totalCards: Int(vocabSheetTotalCards),
                    lastReviewed: vocabSheetLastReviewed,
                    lastUpdated: vocabSheetLastUpdated,
                    createdAt: vocabSheetCreatedAt,
                    isSynced: vocabSheetIsSynced
                )
            } else {
                LoggerService.shared.log(.warning, "No vocab sheet found with id: \(id)", category: LogCategory.sqliteVocabSheet)
                sqlite3_finalize(statement)
                return nil
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            LoggerService.shared.log(.error, "❌ Error preparing select statement for vocab sheet: \(errorMessage)", category: LogCategory.sqliteVocabSheet)
        }
            sqlite3_finalize(statement)
            return nil
        
    }


    // MARK: - Update Vocab Sheet
    func updateVocabSheet(vocabSheet: VocabSheetModel) {
        let updateQuery = """
            UPDATE VocabSheet 
            SET name = ?, createdBy = ?, totalCards = ?, lastReviewed = ?, lastUpdated = ?, isSynced = ?
            WHERE id = ?;
        """
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, updateQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (vocabSheet.name as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (vocabSheet.createdBy as NSString).utf8String, -1, nil)
            sqlite3_bind_int(statement, 3, Int32(vocabSheet.totalCards))
            sqlite3_bind_double(statement, 4, vocabSheet.lastReviewed?.timeIntervalSince1970 ?? 0)
            sqlite3_bind_double(statement, 5, vocabSheet.lastUpdated.timeIntervalSince1970)
            sqlite3_bind_int(statement, 6, vocabSheet.isSynced ? 1 : 0) // Update isSynced
            sqlite3_bind_text(statement, 7, (vocabSheet.id as NSString).utf8String, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "✅ VocabSheet updated successfully: \(vocabSheet.name)", category: LogCategory.sqliteVocabSheet)
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                LoggerService.shared.log(.error, "❌ Failed to update VocabSheet (\(vocabSheet.name)): \(errorMessage)", category: LogCategory.sqliteVocabSheet)
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            LoggerService.shared.log(.error, "❌ Failed to prepare update statement for VocabSheet (\(vocabSheet.name)): \(errorMessage)", category: LogCategory.sqliteVocabSheet)
        }
        
        sqlite3_finalize(statement)
    }
    
    // MARK: - Fetch Unsynced Vocab Sheets
    func fetchUnsyncedVocabSheets() -> [VocabSheetModel] {
        let selectQuery = "SELECT * FROM VocabSheet WHERE isSynced = 0;"
        var statement: OpaquePointer?
        var unsyncedSheets: [VocabSheetModel] = []
        
        if sqlite3_prepare_v2(db, selectQuery, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let vocabSheetId = String(cString: sqlite3_column_text(statement, 0))
                let vocabSheetName = String(cString: sqlite3_column_text(statement, 1))
                let vocabSheetCreatedBy = String(cString: sqlite3_column_text(statement, 2))
                let vocabSheetTotalCards = sqlite3_column_int(statement, 3)
                let vocabSheetLastReviewed = sqlite3_column_type(statement, 4) == SQLITE_NULL ? nil : Date(timeIntervalSince1970: sqlite3_column_double(statement, 4))
                let vocabSheetLastUpdated = Date(timeIntervalSince1970: sqlite3_column_double(statement, 5))
                let vocabSheetCreatedAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 6))
                let vocabSheetIsSynced = sqlite3_column_int(statement, 7) == 1
                
                unsyncedSheets.append(VocabSheetModel(
                    id: vocabSheetId,
                    name: vocabSheetName,
                    cards: [],
                    createdBy: vocabSheetCreatedBy,
                    totalCards: Int(vocabSheetTotalCards),
                    lastReviewed: vocabSheetLastReviewed,
                    lastUpdated: vocabSheetLastUpdated,
                    createdAt: vocabSheetCreatedAt,
                    isSynced: vocabSheetIsSynced
                ))
            }
            LoggerService.shared.log(.info, "✅ Fetched \(unsyncedSheets.count) unsynced vocab sheets", category: LogCategory.sqliteVocabSheet)

        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            LoggerService.shared.log(.error, "❌ Failed to prepare select statement for unsynced vocab sheets: \(errorMessage)", category: LogCategory.sqliteVocabSheet)
        }
        
        sqlite3_finalize(statement)
        return unsyncedSheets
    }



    // MARK: - Delete Vocab Sheet
    func deleteVocabSheet(_ id: String) {
        let deleteQuery = "DELETE FROM VocabSheet WHERE id = ?;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (id as NSString).utf8String, -1, nil)
            if sqlite3_step(statement) == SQLITE_DONE {
                LoggerService.shared.log(.info, "✅ Vocab sheet deleted successfully (id: \(id))", category: LogCategory.sqliteVocabSheet)
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                LoggerService.shared.log(.error, "❌ Failed to delete vocab sheet (id: \(id)): \(errorMessage)", category: LogCategory.sqliteVocabSheet)
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            LoggerService.shared.log(.error, "❌ Failed to prepare delete statement for vocab sheet (id: \(id)): \(errorMessage)", category: LogCategory.sqliteVocabSheet)
        }
        
        sqlite3_finalize(statement)
    }

        
    // MARK: - Close DB
    func closeDatabase() {
        if sqlite3_close(db) == SQLITE_OK {
            print("Database closed successfully.")
        } else {
            print("Error closing database.")
        }
    }
    
    // MARK: - Clear All Local Caches
    /// Clears all locally cached data from SQLite.
    /// Called during logout or user switch to:
    /// - Protect user privacy
    /// - Prevent stale data from being shown
    /// - Reset offline data for the next session
    func clearAllLocalCaches() {
        clearLocalConversationCache()
        clearLocalMessageCache()
        clearLocalCalendarCache()
        clearLocalVocabSheetsCache()
        clearLocalVocabCardsCache()
        clearLocalMeetingsCache()
        clearLocalProfilesCache()
        clearLocalNotificationsCache()
        clearLocalNotificationSettingsCache()
    }

    
}
