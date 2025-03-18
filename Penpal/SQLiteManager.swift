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
        self.createMatchesTable()
        self.createProfileTable()
        self.createMeetingsTable()
        self.createMyCalendarTable()
        self.createVocabCardTable()
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
    private func createMatchesTable() {
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS Matches (
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
            timestamp DOUBLE
        );
        """
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Matches table created successfully.")
            }
        } else {
            print("Error creating matches table.")
        }
        sqlite3_finalize(statement)
    }
    
    // MARK: -  Cache matches to the SQLite database
    func cacheMatches(_ matches: [PenpalsModel]) {
        let insertQuery = """
        INSERT INTO Matches (userId, penpalId, firstName, lastName, proficiency, hobbies, goals, region, matchScore, status, timestamp)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
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

                if sqlite3_step(statement) == SQLITE_DONE {
                    print("Match cached successfully for \(match.penpalId).")
                } else {
                    print("Failed to cache match for \(match.penpalId).")
                }
            }
            sqlite3_finalize(statement)
        }
    }
    
    // MARK: -  Fetches cached matches for a user from SQLite
    func fetchCachedMatches(for userId: String) -> [PenpalsModel] {
        let query = "SELECT * FROM Matches WHERE userId = ? ORDER BY matchScore DESC"
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
                    status: MatchStatus(rawValue: status) ?? .pending
                )
                matches.append(match)
            }
        }
        sqlite3_finalize(statement)
        return matches
    }
    
    // MARK: - Clears matches older than 7 days
    func clearOldMatches() {
        let cutoffTime = Date().timeIntervalSince1970 - (7 * 24 * 60 * 60) // 7 days in seconds
        let deleteQuery = "DELETE FROM Matches WHERE timestamp < ?"

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_double(statement, 1, cutoffTime)

            if sqlite3_step(statement) == SQLITE_DONE {
                print("Old matches cleared successfully.")
            }
        }
        sqlite3_finalize(statement)
    }
    
    // MARK: - Conversation Specific -
    // MARK: - Fetch Messages for a Specific Conversation
    func fetchMessagesForConversation(conversationId: String) -> [MessagesModel] {
        let query = "SELECT * FROM Messages WHERE senderId = ? ORDER BY sentAt ASC;"
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
            type TEXT NOT NULL
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
        INSERT INTO Messages (id, senderId, text, sentAt, isRead, type)
        VALUES (?, ?, ?, ?, ?, ?);
        """

        var statement: OpaquePointer?

        for message in messages {
            if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (message.id as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 2, (message.senderId as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 3, (message.text as NSString).utf8String, -1, nil)
                sqlite3_bind_double(statement, 4, message.sentAt.timeIntervalSince1970)
                sqlite3_bind_int(statement, 5, message.isRead ? 1 : 0)
                sqlite3_bind_text(statement, 6, (message.type as NSString).utf8String, -1, nil)

                if sqlite3_step(statement) == SQLITE_DONE {
                    print("Message cached successfully: \(message.text)")
                } else {
                    print("Failed to cache message: \(message.text)")
                }
            }
            sqlite3_finalize(statement)
        }
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



    
    
    // MARK:  - Calendar Specific -
    // MARK: - Create Calendar Table
    private func createMyCalendarTable() {
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS MyCalendar (
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            meetingIds TEXT
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
            let insertQuery = "INSERT INTO MyCalendar (id, userId, meetingIds) VALUES (?, ?, ?);"
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
            userId TEXT PRIMARY KEY,
            firstName TEXT,
            lastName TEXT,
            email TEXT,
            emailVerified BOOLEAN,
            passwordHash TEXT,
            region TEXT,
            language TEXT,
            country TEXT,
            proficiency TEXT,
            goals TEXT,
            profileImage TEXT,
            hobbies TEXT,
            createdAt DOUBLE,
            updatedAt DOUBLE
        );
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Profiles table created successfully.")
            }
        } else {
            print("Error creating profiles table.")
        }
        sqlite3_finalize(statement)
    }
    
    // MARK: - Insert Profile into SQLite
    func insertProfile(_ profile: UserProfileModel) {
        let insertQuery = """
        INSERT INTO Profiles (userId, firstName, lastName, email, emailVerified, passwordHash, region, language, country, proficiency, goals, profileImage, hobbies, createdAt, updatedAt)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (profile.userId as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (profile.firstName as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (profile.lastName as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 4, (profile.email as NSString).utf8String, -1, nil)
            sqlite3_bind_int(statement, 5, profile.emailVerified ? 1 : 0)
            sqlite3_bind_text(statement, 6, (profile.passwordHash as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 7, (profile.region as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 8, (profile.language as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 9, (profile.country as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 10, (profile.proficiency as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 11, (profile.goals as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 12, (profile.profileImage as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 13, (profile.hobbies.joined(separator: ",") as NSString).utf8String, -1, nil)
            sqlite3_bind_double(statement, 14, profile.createdAt)
            sqlite3_bind_double(statement, 15, profile.updatedAt)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Profile inserted successfully for \(profile.userId).")
            } else {
                print("Failed to insert profile for \(profile.userId).")
            }
        }
        sqlite3_finalize(statement)
    }
    
    
    // MARK: - Fetch Profile by User ID
    func fetchProfile(for userId: String) -> UserProfileModel? {
        let query = "SELECT * FROM Profiles WHERE userId = ?"
        var statement: OpaquePointer?
        var profile: UserProfileModel? = nil
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (userId as NSString).utf8String, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_ROW {
                let firstName = String(cString: sqlite3_column_text(statement, 1))
                let lastName = String(cString: sqlite3_column_text(statement, 2))
                let email = String(cString: sqlite3_column_text(statement, 3))
                let emailVerified = sqlite3_column_int(statement, 4) != 0
                let passwordHash = String(cString: sqlite3_column_text(statement, 5))
                let region = String(cString: sqlite3_column_text(statement, 6))
                let language = String(cString: sqlite3_column_text(statement, 7))
                let country = String(cString: sqlite3_column_text(statement, 8))
                let proficiency = String(cString: sqlite3_column_text(statement, 9))
                let goals = String(cString: sqlite3_column_text(statement, 10))
                let profileImage = String(cString: sqlite3_column_text(statement, 11))
                let hobbiesString = String(cString: sqlite3_column_text(statement, 12))
                let hobbies = hobbiesString.components(separatedBy: ",")
                let createdAt = sqlite3_column_double(statement, 13)
                let updatedAt = sqlite3_column_double(statement, 14)
                
                profile = UserProfileModel(
                    userId: userId,
                    firstName: firstName,
                    lastName: lastName,
                    email: email,
                    emailVerified: emailVerified,
                    passwordHash: passwordHash,
                    region: region,
                    language: language,
                    country: country,
                    proficiency: proficiency,
                    goals: goals,
                    profileImage: profileImage,
                    hobbies: hobbies,
                    createdAt: createdAt,
                    updatedAt: updatedAt
                )
            }
        }
        sqlite3_finalize(statement)
        return profile
    }
    
    // MARK: - Update Profile in SQLite
    func updateProfile(_ profile: UserProfileModel) {
        let updateQuery = """
        UPDATE Profiles SET
        firstName = ?, lastName = ?, email = ?, emailVerified = ?, passwordHash = ?, region = ?, language = ?, country = ?, proficiency = ?, goals = ?, profileImage = ?, hobbies = ?, updatedAt = ?
        WHERE userId = ?;
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, updateQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (profile.firstName as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (profile.lastName as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (profile.email as NSString).utf8String, -1, nil)
            sqlite3_bind_int(statement, 4, profile.emailVerified ? 1 : 0)
            sqlite3_bind_text(statement, 5, (profile.passwordHash as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 6, (profile.region as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 7, (profile.language as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 8, (profile.country as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 9, (profile.proficiency as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 10, (profile.goals as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 11, (profile.profileImage as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 12, (profile.hobbies.joined(separator: ",") as NSString).utf8String, -1, nil)
            sqlite3_bind_double(statement, 13, profile.updatedAt)
            sqlite3_bind_text(statement, 14, (profile.userId as NSString).utf8String, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Profile updated successfully for \(profile.userId).")
            } else {
                print("Failed to update profile for \(profile.userId).")
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
            front TEXT,
            back TEXT,
            addedBy TEXT NOT NULL,
            favorited INTEGER NOT NULL DEFAULT 0,
            createdAt REAL NOT NULL,
            updatedAt REAL NOT NULL,
            lastReviewed REAL
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

    
    // MARK: - Create Vocab Card
    func createVocabCard(vocabCard: VocabCardModel) {
        let insertQuery = """
            INSERT INTO VocabCard (id, front, back, addedBy, favorited, createdAt, updatedAt, lastReviewed) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        """
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (vocabCard.id as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (vocabCard.front as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (vocabCard.back as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 4, (vocabCard.addedBy as NSString).utf8String, -1, nil)
            sqlite3_bind_int(statement, 5, vocabCard.favorited ? 1 : 0)
            sqlite3_bind_double(statement, 6, vocabCard.createdAt.timeIntervalSince1970)
            sqlite3_bind_double(statement, 7, vocabCard.updatedAt.timeIntervalSince1970)
            
            if let lastReviewed = vocabCard.lastReviewed {
                sqlite3_bind_double(statement, 8, lastReviewed.timeIntervalSince1970)
            } else {
                sqlite3_bind_null(statement, 8)
            }
            
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Vocab card created successfully.")
            } else {
                print("Error creating vocab card.")
            }
        } else {
            print("Error preparing insert statement.")
        }
        
        sqlite3_finalize(statement)
    }
    
    // MARK: - Cache Vocab Cards to the SQLite database
    func cacheVocabCards(_ vocabCards: [VocabCardModel]) {
        let insertQuery = """
        INSERT INTO VocabCard (id, front, back, addedBy, favorited, createdAt, updatedAt, lastReviewed)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        """

        var statement: OpaquePointer?

        for vocabCard in vocabCards {
            if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (vocabCard.id as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 2, (vocabCard.front as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 3, (vocabCard.back as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 4, (vocabCard.addedBy as NSString).utf8String, -1, nil)
                sqlite3_bind_int(statement, 5, vocabCard.favorited ? 1 : 0)
                sqlite3_bind_double(statement, 6, vocabCard.createdAt.timeIntervalSince1970)
                sqlite3_bind_double(statement, 7, vocabCard.updatedAt.timeIntervalSince1970)

                if let lastReviewed = vocabCard.lastReviewed {
                    sqlite3_bind_double(statement, 8, lastReviewed.timeIntervalSince1970)
                } else {
                    sqlite3_bind_null(statement, 8)
                }

                if sqlite3_step(statement) == SQLITE_DONE {
                    print("Vocab card cached successfully: \(vocabCard.front)")
                } else {
                    print("Failed to cache vocab card: \(vocabCard.front)")
                }
            }
            sqlite3_finalize(statement)
        }
    }


    // MARK: - Fetch Vocab Card
    func fetchVocabCard(id: String) -> VocabCardModel? {
        let selectQuery = "SELECT * FROM VocabCard WHERE id = ?;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, selectQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (id as NSString).utf8String, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_ROW {
                let vocabCardId = String(cString: sqlite3_column_text(statement, 0))
                let vocabCardFront = String(cString: sqlite3_column_text(statement, 1))
                let vocabCardBack = String(cString: sqlite3_column_text(statement, 2))
                let vocabCardAddedBy = String(cString: sqlite3_column_text(statement, 3))
                let vocabCardFavorited = sqlite3_column_int(statement, 4) == 1
                let vocabCardCreatedAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 5))
                let vocabCardUpdatedAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 6))
                let vocabCardLastReviewed = sqlite3_column_type(statement, 7) == SQLITE_NULL ? nil : Date(timeIntervalSince1970: sqlite3_column_double(statement, 7))
                
                sqlite3_finalize(statement)
                return VocabCardModel(
                    id: vocabCardId,
                    front: vocabCardFront,
                    back: vocabCardBack,
                    addedBy: vocabCardAddedBy,
                    favorited: vocabCardFavorited,
                    createdAt: vocabCardCreatedAt,
                    updatedAt: vocabCardUpdatedAt,
                    lastReviewed: vocabCardLastReviewed
                )
            } else {
                print("No vocab card found with id: \(id)")
                sqlite3_finalize(statement)
                return nil
            }
        } else {
            print("Error preparing select statement.")
            sqlite3_finalize(statement)
            return nil
        }
    }

    // MARK: - Update Vocab Card
    func updateVocabCard(vocabCard: VocabCardModel) {
        let updateQuery = """
            UPDATE VocabCard 
            SET front = ?, back = ?, addedBy = ?, favorited = ?, updatedAt = ?, lastReviewed = ? 
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
            
            sqlite3_bind_text(statement, 7, (vocabCard.id as NSString).utf8String, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Vocab card updated successfully.")
            } else {
                print("Error updating vocab card.")
            }
        } else {
            print("Error preparing update statement.")
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
        
    // MARK: - Close DB
    func closeDatabase() {
        if sqlite3_close(db) == SQLITE_OK {
            print("Database closed successfully.")
        } else {
            print("Error closing database.")
        }
    }
    
}
