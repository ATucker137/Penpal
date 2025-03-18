import Foundation

class VocabSheetModel: Identifiable, Codable {
    
    var id: String
    var name: String
    var cards: [VocabCardModel]
    var createdBy: String // Profile ID
    var totalCards: Int
    var lastReviewed: Date?
    var lastUpdated: Date
    var createdAt: Date
    
    // Initializer to create a VocabSheetModel instance
    init(id: String, name: String, cards: [VocabCardModel], createdBy: String, totalCards: Int, lastReviewed: Date?, lastUpdated: Date, createdAt: Date) {
        self.id = id
        self.name = name
        self.cards = cards
        self.createdBy = createdBy
        self.totalCards = totalCards
        self.lastReviewed = lastReviewed
        self.lastUpdated = lastUpdated
        self.createdAt = createdAt
    }
    
    // MARK: - Convert to Firestore
    // Converts the model into a dictionary format suitable for Firestore storage
    func toFireStoreData() -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "cards": cards.map { $0.toFireStoreData() }, // Convert cards to dictionary format
            "createdBy": createdBy,
            "totalCards": totalCards,
            "lastReviewed": lastReviewed?.timeIntervalSince1970 ?? NSNull(), // Store as Unix timestamp
            "lastUpdated": lastUpdated.timeIntervalSince1970,
            "createdAt": createdAt.timeIntervalSince1970
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
              let cardsData = data["cards"] as? [[String: Any]] else {
            return nil
        }
        
        // Convert optional lastReviewed timestamp if it exists
        let lastReviewedTimestamp = data["lastReviewed"] as? Double
        let lastReviewed = lastReviewedTimestamp != nil ? Date(timeIntervalSince1970: lastReviewedTimestamp!) : nil
        // Convert each Firestore dictionary back into VocabCardModel objects
        let cards = cardsData.compactMap { VocabCardModel.fromFireStoreData($0) }

        return VocabSheetModel(id: id, name: name, cards: cards, createdBy: createdBy, totalCards: totalCards, lastReviewed: lastReviewed, lastUpdated: Date(timeIntervalSince1970: lastUpdatedTimestamp), createdAt: Date(timeIntervalSince1970: createdAtTimestamp))
    }
    
    // MARK: - Convert to SQLite
    // Converts the model into a dictionary format suitable for SQLite storage
    func toSQLite() -> [String: Any] {
        // Encode cards array into a JSON string
        let encodedCards = try? JSONEncoder().encode(cards)
        let cardsString = encodedCards != nil ? String(data: encodedCards!, encoding: .utf8) ?? "[]" : "[]"
        
        return [
            "id": id,
            "name": name,
            "cards": cardsString,
            "createdBy": createdBy,
            "totalCards": totalCards,
            "lastUpdated": lastUpdated.timeIntervalSince1970,
            "lastReviewed": lastReviewed?.timeIntervalSince1970 ?? NSNull(),
            "createdAt": createdAt.timeIntervalSince1970
        ]
    }
    
    // MARK: - Convert from SQLite
    // Initializes a VocabSheetModel from SQLite dictionary data
    static func fromSQLite(_ data: [String: Any]) -> VocabSheetModel? {
        // Extracting basic fields from the SQLite dictionary
        guard let id = data["id"] as? String,  // Unique ID of the vocab sheet
              let name = data["name"] as? String, // Name of the vocab sheet
              
              // Extract the stored JSON string representation of cards
              let cardsString = data["cards"] as? String,
              
              // Convert the JSON string into Data format
              let cardsData = cardsString.data(using: .utf8),
              
              // Decode the Data back into an array of VocabCardModel objects
              let decodedCards = try? JSONDecoder().decode([VocabCardModel].self, from: cardsData),
              
              let createdBy = data["createdBy"] as? String, // ID of the user who created it
              let totalCards = data["totalCards"] as? Int, // Number of vocab cards
              
              // Extract timestamps stored as Unix time (seconds since 1970)
              let lastUpdatedTimestamp = data["lastUpdated"] as? Double, // Last time the sheet was updated
              let createdAtTimestamp = data["createdAt"] as? Double // When the sheet was created
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
            cards: decodedCards,
            createdBy: createdBy,
            totalCards: totalCards,
            lastReviewed: lastReviewed ?? Date(), // Use current date if lastReviewed is nil
            lastUpdated: lastUpdated,
            createdAt: createdAt
        )
    }

}
