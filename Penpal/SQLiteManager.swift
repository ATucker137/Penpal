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
    
    //MARK: - Penpal Component Specific -
    // TODO: - Adjust the PenpalService to fit with SQL Lite And Needs more work overall
    
    

    // MARK: - Creates a Matches Table
    private func createPenpalsTable() {
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS Penpals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId TEXT,
            penpalId TEXT,
            firstName TEXT,
            lastName TEXT,
            proficiency TEXT,
            hobbies TEXT,
            goals TEXT,
            region TEXT,
            matchScore INTEGER,
            status TEXT,
            timestamp DOUBLE,
            isSynced BOOLEAN
        );
        """
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Penpals table created successfully.")
            }
        } else {
            print("Error creating Penpals table.")
        }
        sqlite3_finalize(statement)
    }
    // MARK: - This will pull All Penpals that are accepted
    func getAllPenpals(for userId: String) -> [PenpalsModel] {
        let query = "SELECT * FROM Penpals WHERE userId = ? AND status = 'accepted'"
        var statement: OpaquePointer?
        var penpals: [PenpalsModel] = []

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (userId as NSString).utf8String, -1, nil)

            while sqlite3_step(statement) == SQLITE_ROW {
                let penpalId = sqlite3_column_text(statement, 1).map { String(cString: $0) } ?? ""
                let firstName = sqlite3_column_text(statement, 3).map { String(cString: $0) } ?? ""
                let lastName = sqlite3_column_text(statement, 4).map { String(cString: $0) } ?? ""
                let proficiency = sqlite3_column_text(statement, 5).map { String(cString: $0) } ?? ""
                let hobbiesString = sqlite3_column_text(statement, 6).map { String(cString: $0) } ?? ""
                let hobbies = hobbiesString.components(separatedBy: ",")
                let goals = sqlite3_column_text(statement, 7).map { String(cString: $0) } ?? ""
                let region = sqlite3_column_text(statement, 8).map { String(cString: $0) } ?? ""
                let matchScore = Int(sqlite3_column_int(statement, 9))
                let status = sqlite3_column_text(statement, 10).map { String(cString: $0) } ?? "pending"
                let isSynced = sqlite3_column_int(statement, 11) == 1

                let penpal = PenpalsModel(
                    userId: userId,
                    penpalId: penpalId,
                    firstName: firstName,
                    lastName: lastName,
                    proficiency: proficiency,
                    hobbies: hobbies,
                    goals: goals,
                    region: region,
                    matchScore: matchScore,
                    status: MatchStatus(rawValue: status) ?? .pending,
                    isSynced: isSynced
                )

                penpals.append(penpal)
            }
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
            }
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
                print("Penpal synced successfully.")
            } else {
                print("Failed to sync penpal.")
            }
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
                sqlite3_finalize(statement)
                return true
            }
        }
        sqlite3_finalize(statement)
        return false
    }

    // MARK: - Accept Friend Request
    func acceptFriendRequest(from penpalId: String, for userId: String) -> Bool {
        let query = "UPDATE Penpals SET status = 'accepted' WHERE penpalId = ? AND userId = ?"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (penpalId as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (userId as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
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
                print("Enforced penpal limit successfully.")
            }
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
                sqlite3_finalize(statement)
                return true
            }
        }
        sqlite3_finalize(statement)
        return false
    }


    
    // MARK: -  Cache matches to the SQLite database
    func cachePenpals(_ matches: [PenpalsModel]) {
        // TODO: - Prevent duplicate entries by using `INSERT OR REPLACE`
            // OR clearing existing cache before inserting.
            // Recommended: Add `PRIMARY KEY (userId, penpalId)` to the table
            // and change the insert query to:
            // let insertQuery = "INSERT OR REPLACE INTO Penpals (...) VALUES (...);"
        let insertQuery = """
        INSERT INTO Penpals (userId, penpalId, firstName, lastName, proficiency, hobbies, goals, region, matchScore, status, timestamp, isSynced)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """

        var statement: OpaquePointer?
        
        for match in matches {
            if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (match.userId as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 2, (match.penpalId as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 3, (match.firstName as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 4, (match.lastName as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 5, (match.proficiency as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 6, (match.hobbies.joined(separator: ",") as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 7, (match.goals as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 8, (match.region as NSString).utf8String, -1, nil)
                sqlite3_bind_int(statement, 9, Int32(match.matchScore))
                sqlite3_bind_text(statement, 10, (match.status.rawValue as NSString).utf8String, -1, nil)
                sqlite3_bind_double(statement, 11, Date().timeIntervalSince1970)
                sqlite3_bind_int(statement, 12, match.isSynced ? 1 : 0)


                if sqlite3_step(statement) == SQLITE_DONE {
                    print("Penpal cached successfully for \(match.penpalId).")
                } else {
                    print("Failed to cache match for \(match.penpalId).")
                }
            }
            sqlite3_finalize(statement)
        }
    }
    
    // MARK: - Send Friend Request
    func sendFriendRequest(to penpalId: String, from userId: String) -> Bool {
        let query = """
        INSERT INTO Penpals (userId, penpalId, status, isSynced) 
        VALUES (?, ?, 'pending', 0)
        ON CONFLICT(userId, penpalId) DO UPDATE SET status = 'pending';
        """
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (userId as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (penpalId as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
        }
        sqlite3_finalize(statement)
        return false
    }

    // MARK: -  Fetches cached matches for a user from SQLite
    func fetchCachedPenpals(for userId: String) -> [PenpalsModel] {
        let query = "SELECT * FROM Penpals WHERE userId = ? ORDER BY matchScore DESC"
        var statement: OpaquePointer?
        var matches: [PenpalsModel] = []

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (userId as NSString).utf8String, -1, nil)

            while sqlite3_step(statement) == SQLITE_ROW {
                let penpalId = String(cString: sqlite3_column_text(statement, 2))
                let firstName = String(cString: sqlite3_column_text(statement, 3))
                let lastName = String(cString: sqlite3_column_text(statement, 4))
                let proficiency = String(cString: sqlite3_column_text(statement, 5))
                let hobbiesString = String(cString: sqlite3_column_text(statement, 6))
                let hobbies = hobbiesString.components(separatedBy: ",")
                let goals = String(cString: sqlite3_column_text(statement, 7))
                let region = String(cString: sqlite3_column_text(statement, 8))
                let matchScore = Int(sqlite3_column_int(statement, 9))
                let status = String(cString: sqlite3_column_text(statement, 10))
                let isSynced = sqlite3_column_int(statement, 11) == 1


                let match = PenpalsModel(
                    userId: userId,
                    penpalId: penpalId,
                    firstName: firstName,
                    lastName: lastName,
                    proficiency: proficiency,
                    hobbies: hobbies,
                    goals: goals,
                    region: region,
                    matchScore: matchScore,
                    status: MatchStatus(rawValue: status) ?? .pending,
                    isSynced: isSynced
                )
                matches.append(match)
            }
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
                print("Old Penpals cleared successfully.")
            }
        }
        sqlite3_finalize(statement)
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
                print("Conversations table created successfully.")
            } else {
                print("Failed to create Conversations table.")
            }
        } else {
            print("Error preparing Conversations table creation statement.")
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
                print("Conversation deleted locally: \(conversationId)")
            } else {
                print("Failed to delete conversation locally.")
            }
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
            print("Failed to encode participants array.")
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
                print("Successfully inserted conversation: \(conversationId)")
            } else {
                print("Failed to insert conversation: \(conversationId)")
            }
        } else {
            print("Error preparing insert statement for conversation.")
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
                    print("Conversation cached: \(convo.id)")
                } else {
                    print("Failed to cache conversation: \(convo.id)")
                }
            } else {
                print("Error preparing cache insert statement for conversation: \(convo.id)")
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
                }
            }
        } else {
            print("Error fetching conversations from database.")
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
                }
            }
        } else {
            print("Error fetching conversation messages.")
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
                print("Successfully updated local last message for conversation \(conversationId)")
            } else {
                print("Failed to update last message locally")
            }
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
                print("Local cache cleared successfully.")
            } else {
                print("Failed to clear local cache.")
            }
        } else {
            print("Failed to prepare delete statement for clearing local cache.")
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
        } else {
            print("Search query failed.")
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
                print("Messages table created successfully.")
            }
        } else {
            print("Error creating Messages table.")
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
                    print("Message cached successfully: \(message.text)")
                } else {
                    print("Failed to cache message: \(message.text)")
                }
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
                print("Local message cache cleared successfully.")
            } else {
                print("Failed to clear local message cache.")
            }
        } else {
            print("Failed to prepare delete statement for message cache.")
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
            print("Error fetching messages.")
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
                print("Failed to update message status for ID: \(messageId)")
            }
        } else {
            print("Failed to prepare update statement for message status.")
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
            print("Failed to prepare fetchFailedMessages query.")
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
                    print("Unread message: \(message.text)")
                }
            }
        } else {
            print("Failed to prepare fetchUnreadMessages query.")
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
                print("Failed to mark message as read: \(messageId)")
            }
        } else {
            print("Failed to prepare update statement for marking message as read.")
        }

        sqlite3_finalize(statement)
    }
    
    // Helper to parse a row into a MessagesModel
    private func parseMessageRow(statement: OpaquePointer?) -> MessagesModel? {
        guard let statement = statement else { return nil }

        guard
            let idCStr = sqlite3_column_text(statement, 0),
            let senderIdCStr = sqlite3_column_text(statement, 1),
            let textCStr = sqlite3_column_text(statement, 2),
            let typeCStr = sqlite3_column_text(statement, 5),
            let statusCStr = sqlite3_column_text(statement, 7)
        else { return nil }

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
                print("MyCalendar table created successfully.")
            } else {
                print("Failed to create MyCalendar table.")
            }
        } else {
            print("Error preparing CREATE TABLE statement.")
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
                print("Local calendar cache cleared successfully.")
            } else {
                print("Failed to clear local calendar cache.")
            }
        } else {
            print("Failed to prepare delete statement for calendar cache.")
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
                sqlite3_finalize(statement)
                
                return MyCalendar(id: id, userId: userId, meetingIds: meetingIds)
            }
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
                print("MyCalendar updated successfully.")
            } else {
                print("Failed to update MyCalendar.")
            }
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
                    print("MyCalendar cached successfully.")
                } else {
                    print("Failed to cache MyCalendar.")
                }
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
                print("✅ Profiles table created successfully.")
            } else {
                print("❌ Failed to execute table creation step.")
            }
        } else {
            print("❌ Failed to prepare create table statement.")
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
                print("Local profiles cache cleared successfully.")
            } else {
                print("Failed to clear local profiles cache.")
            }
        } else {
            print("Failed to prepare delete statement for profiles cache.")
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
                print("✅ Profile inserted successfully for \(profile.id).")
            } else {
                print("❌ Failed to insert profile. Error: \(String(cString: sqlite3_errmsg(db)))")
            }
        } else {
            print("❌ Failed to prepare insert statement. Error: \(String(cString: sqlite3_errmsg(db)))")
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
            }
        } else {
            print("❌ Failed to prepare fetch statement. Error: \(String(cString: sqlite3_errmsg(db)))")
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
                print("✅ Profile updated successfully for \(profile.id).")
            } else {
                print("❌ Failed to update profile. Error: \(String(cString: sqlite3_errmsg(db)))")
            }
        } else {
            print("❌ Failed to prepare update statement. Error: \(String(cString: sqlite3_errmsg(db)))")
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
                return true
            }
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
                print("❌ Failed to update sync status for \(userId)")
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
                print("Error deleting profile with userId \(userId)")
            }
        } else {
            print("Failed to prepare delete statement.")
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
            print("❌ Profile Error: \(error.localizedDescription)")
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
                print("✅ Deleted profile \(userId)")
            } else {
                print("❌ Failed to delete profile.")
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
                print("Meetings table created successfully.")
            }
        } else {
            print("Error creating meetings table.")
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
                print("Local meetings cache cleared successfully.")
            } else {
                print("Failed to clear local meetings cache.")
            }
        } else {
            print("Failed to prepare delete statement for meetings cache.")
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
                    print("Error inserting meeting")
                }
                sqlite3_reset(statement)
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
                print("Meeting inserted successfully.")
            } else {
                print("Error inserting meeting.")
            }
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
                print("Meeting updated successfully.")
            } else {
                print("Error updating meeting.")
            }
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
                print("Meeting status updated successfully.")
            } else {
                print("Failed to update meeting status.")
            }
        } else {
            print("Failed to prepare statement.")
        }

        sqlite3_finalize(statement)
    }


    // MARK: -  Delete Meetings Table
    func deleteMeeting(_ meetingID: String) {
        let deleteQuery = "DELETE FROM Meetings WHERE id = ?;"
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (meetingID as NSString).utf8String, -1, nil)
            sqlite3_step(statement)
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
                print("VocabCard table created successfully.")
            }
        } else {
            print("Error creating VocabCard table.")
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
                print("Local vocab cards cache cleared successfully.")
            } else {
                print("Failed to clear local vocab cards cache.")
            }
        } else {
            print("Failed to prepare delete statement for vocab cards cache.")
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
                print("Vocab card created successfully.")
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("Error creating vocab card: \(errorMessage)")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("Error preparing insert statement: \(errorMessage)")
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
                    print("Vocab card cached successfully: \(vocabCard.front)")
                } else {
                    let errorMessage = String(cString: sqlite3_errmsg(db))
                    print("Failed to cache vocab card (\(vocabCard.front)): \(errorMessage)")
                }

                sqlite3_reset(statement)
                sqlite3_clear_bindings(statement)
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("Error preparing insert statement: \(errorMessage)")
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
                print("No vocab card found with sheetId: \(sheetId) and id: \(id)")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("Error preparing select statement: \(errorMessage)")
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
                print("Vocab card updated successfully: \(vocabCard.front)")
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("❌ Error updating vocab card: \(errorMessage)")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("❌ Error preparing update statement: \(errorMessage)")
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
                print("Vocab card deleted successfully.")
            } else {
                print("Error deleting vocab card.")
            }
        } else {
            print("Error preparing delete statement.")
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
                print("VocabSheet table created successfully.")
            }
        } else {
            print("Error creating VocabSheet table.")
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
                print("Local vocab sheet cache cleared successfully.")
            } else {
                print("Failed to clear local vocab sheet cache.")
            }
        } else {
            print("Failed to prepare delete statement for vocab sheet cache.")
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
                print("Vocab sheet created successfully.")
            } else {
                print("Error creating vocab sheet.")
            }
        } else {
            print("Error preparing insert statement.")
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
                print("No vocab sheet found with id: \(id)")
                sqlite3_finalize(statement)
                return nil
            }
        } else {
            print("Error preparing select statement.")
            sqlite3_finalize(statement)
            return nil
        }
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
                print("Vocab sheet updated successfully.")
            } else {
                print("Error updating vocab sheet.")
            }
        } else {
            print("Error preparing update statement.")
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
                print("Vocab sheet deleted successfully.")
            } else {
                print("Error deleting vocab sheet.")
            }
        } else {
            print("Error preparing delete statement.")
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
    }

    
}
