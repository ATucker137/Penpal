import Foundation

class VocabSheetModel: Identifiable, Codable {
    
    var id: String
    var name: String
    var createdBy: String // Profile ID
    var totalCards: Int
    var lastReviewed: Date?
    var lastUpdated: Date
    var createdAt: Date
    var isSynced: Bool // isSynced is equal to whether
    
    // Initializer to create a VocabSheetModel instance
    init(id: String, name: String, createdBy: String, totalCards: Int, lastReviewed: Date?, lastUpdated: Date, createdAt: Date, isSynced: Bool) {
        self.id = id
        self.name = name
        self.createdBy = createdBy
        self.totalCards = totalCards
        self.lastReviewed = lastReviewed
        self.lastUpdated = lastUpdated
        self.createdAt = createdAt
        self.isSynced = isSynced
    }
    
    // MARK: - Convert to Firestore
    // Converts the model into a dictionary format suitable for Firestore storage
    func toFireStoreData() -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "createdBy": createdBy,
            "totalCards": totalCards,
            "lastReviewed": lastReviewed?.timeIntervalSince1970 ?? NSNull(), // Store as Unix timestamp
            "lastUpdated": lastUpdated.timeIntervalSince1970,
            "createdAt": createdAt.timeIntervalSince1970,
            "isSynced": isSynced
        ]
    }
    // MARK: - Convert from Firestore Format
    // Initializes a VocabSheetModel from Firestore dictionary data
    static func fromFireStoreData(_ data: [String: Any]) -> VocabSheetModel? {
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let createdBy = data["createdBy"] as? String,
              let totalCards = data["totalCards"] as? Int,
              let lastUpdatedTimestamp = data["lastUpdated"] as? Double,
              let createdAtTimestamp = data["createdAt"] as? Double,
              let isSynced = data["isSynced"] as? Bool else {
            return nil
        }
        
        // Convert optional lastReviewed timestamp if it exists
        let lastReviewedTimestamp = data["lastReviewed"] as? Double
        let lastReviewed = lastReviewedTimestamp != nil ? Date(timeIntervalSince1970: lastReviewedTimestamp!) : nil
        // Convert each Firestore dictionary back into VocabCardModel objects

        return VocabSheetModel(id: id, name: name, createdBy: createdBy, totalCards: totalCards, lastReviewed: lastReviewed, lastUpdated: Date(timeIntervalSince1970: lastUpdatedTimestamp), createdAt: Date(timeIntervalSince1970: createdAtTimestamp), isSynced: isSynced)
    }
    
    // MARK: - Convert to SQLite
    // Converts the model into a dictionary format suitable for SQLite storage
    func toSQLite() -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "createdBy": createdBy,
            "totalCards": totalCards,
            "lastUpdated": lastUpdated.timeIntervalSince1970,
            "lastReviewed": lastReviewed?.timeIntervalSince1970 ?? NSNull(),
            "createdAt": createdAt.timeIntervalSince1970,
            "isSynced": isSynced
        ]
    }
    
    // MARK: - Convert from SQLite
    // Initializes a VocabSheetModel from SQLite dictionary data
    static func fromSQLite(_ data: [String: Any]) -> VocabSheetModel? {
        // Extracting basic fields from the SQLite dictionary
        guard let id = data["id"] as? String,  // Unique ID of the vocab sheet
              let name = data["name"] as? String, // Name of the vocab sheet
              

              let createdBy = data["createdBy"] as? String, // ID of the user who created it
              let totalCards = data["totalCards"] as? Int, // Number of vocab cards
              
              // Extract timestamps stored as Unix time (seconds since 1970)
              let lastUpdatedTimestamp = data["lastUpdated"] as? Double, // Last time the sheet was updated
              let createdAtTimestamp = data["createdAt"] as? Double, // When the sheet was created
              let isSynced = data["isSynced"] as? Bool // if sheet is synced to firebase
        else {
            // If any of the required fields are missing or of the wrong type, return nil
            return nil
        }
        
        // Extract lastReviewed timestamp if it exists, otherwise set to nil
        let lastReviewedTimestamp = data["lastReviewed"] as? Double
        let lastReviewed = lastReviewedTimestamp.map { Date(timeIntervalSince1970: $0) } // Convert timestamp to Date
        
        // Convert timestamps to Date objects for proper handling
        let lastUpdated = Date(timeIntervalSince1970: lastUpdatedTimestamp)
        let createdAt = Date(timeIntervalSince1970: createdAtTimestamp)

        // Return a fully constructed VocabSheetModel instance
        return VocabSheetModel(
            id: id,
            name: name,
            createdBy: createdBy,
            totalCards: totalCards,
            lastReviewed: lastReviewed, // Use current date if lastReviewed is nil
            lastUpdated: lastUpdated,
            createdAt: createdAt,
            isSynced: isSynced
        )
    }

}
