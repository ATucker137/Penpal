import Foundation
import SQLite3

/*
 Reason For Struct:

 Value Semantics:
 Structs are value types, meaning when you pass them around, you get copies rather than references.
 This helps avoid unintended side effects and makes them safer for multithreading.

 Performance:
 Structs are stored on the stack, making them faster for read-heavy operations compared to class instances,
 which are stored on the heap and require reference counting.
*/

// MARK: - ConversationsModel - The Model that will define the list of Conversations
// CodingKeys and the Codable protocol are necessary for interacting with Firestore,
// allowing easy encoding and decoding. Using an enum here is a good practice to map
// the model's properties to Firestore's field names. The enum ensures type safety and flexibility
// in handling any differences between the struct's property names and Firestore's field names.

struct ConversationsModel: Codable, Identifiable {
    
    var id: String           // Unique identifier for each conversation
    var participants: [String]      // Array of user IDs in the conversation (typically 2 users)
var lastMessage: String? // Optional: The last message in the conversation
    var lastUpdated: Date    // Timestamp of the most recent activity in the conversation
    var isSynced: Bool       // Indicates whether the conversation is synced with Firestore

    enum CodingKeys: String, CodingKey {
        case id, participants, lastMessage, lastUpdated, isSynced
    }
    // Helper computed properties to get userId and penpalId based on the current userId
    func penpalId(for currentUserId: String) -> String? {
        return participants.first { $0 != currentUserId }
    }
    
    // MARK: - From Firestore Data
    static func fromFireStoreData(_ data: [String: Any]) -> ConversationsModel? {
        guard let id = data["id"] as? String,
              let participants = data["participants"] as? [String],
              let lastUpdated = data["lastUpdated"] as? Date,
              let isSynced = data["isSynced"] as? Bool else {
            return nil
        }

        // Optional lastMessage
        let lastMessage = data["lastMessage"] as? String
        
        return ConversationsModel(
            id: id,
            participants: participants,
            lastMessage: lastMessage,
            lastUpdated: lastUpdated,
            isSynced: isSynced
        )
    }
    
    // MARK: - From SQLite Data
    static func fromSQLiteData(statement: OpaquePointer?) -> ConversationsModel? {
        guard let statement = statement else { return nil }
        
        let id = String(cString: sqlite3_column_text(statement, 0))
        // Assuming participants are stored as a JSON string in SQLite
        let participantsJson = String(cString: sqlite3_column_text(statement, 1))
        let participantsData = participantsJson.data(using: .utf8) ?? Data()
        let participants = (try? JSONDecoder().decode([String].self, from: participantsData)) ?? []
        
        var lastMessage: String? = nil
        if let textPointer = sqlite3_column_text(statement, 2) {
            lastMessage = String(cString: textPointer)
        }
        
        let lastUpdated = Date(timeIntervalSince1970: sqlite3_column_double(statement, 3))
        let isSynced = sqlite3_column_int(statement, 4) == 1
        
        return ConversationsModel(
            id: id,
            participants: participants,
            lastMessage: lastMessage,
            lastUpdated: lastUpdated,
            isSynced: isSynced
        )
    }

    // MARK: - To Firestore Data
    func toFireStoreData() -> [String: Any] {
        return [
            "id": id,
            "participants": participants,
            "lastMessage": lastMessage ?? "",
            "lastUpdated": lastUpdated,
            "isSynced": isSynced
        ]
    }

    // MARK: - To SQLite Data
    func toSQLiteData() -> [String: Any] {
        
        // Serialize participants array to JSON string for SQLite storage
            
        let participantsJson: String
        do {
            let data = try JSONEncoder().encode(participants)
            participantsJson = String(data: data, encoding: .utf8) ?? "[]"
        } catch {
            print("❌ Failed to encode participants: \(error)")
            participantsJson = "[]"
        }
        return [
            "id": id,
            "participants": participantsJson,
            "lastMessage": lastMessage ?? "",
            "lastUpdated": lastUpdated.timeIntervalSince1970,
            "isSynced": isSynced ? 1 : 0
        ]
    }
}
