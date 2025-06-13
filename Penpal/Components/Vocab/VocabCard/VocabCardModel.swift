// VocabCardModel.swift
// Penpal
//
// Created by Austin William Tucker on 11/29/24.
//
import FirebaseFirestore
// MARK: - VocabCardModel
/// A model representing a vocabulary card, with functionality to convert to and from Firestore data.
class VocabCardModel: Codable, Identifiable {
    
    // MARK: - Properties
    
    /// Unique identifier for the vocabulary card.
    var id: String
    /// Unique identifier for the vocabulary sheet.
    var sheetId: String
    /// Name or term of the vocabulary card (front of the card).
    var front: String
    /// Definition or translation of the vocabulary card (back of the card).
    var back: String
    /// ID of the user who created or added the card.
    var addedBy: String
    /// A boolean value indicating whether the card has been favorited.
    var favorited: Bool
    /// Timestamp for when the card was created.
    var createdAt: Date
    /// Timestamp for the last time the card was updated.
    var updatedAt: Date
    /// The last time the card was reviewed by the user.
    var lastReviewed: Date?
    /// Whether or not the data has been synced to Firestore
    var isSynced: Bool
    
    // MARK: - Initializer
    
    /// Initializes a new instance of `VocabCardModel`.
    /// - Parameters:
    ///   - id: The unique identifier for the vocabulary card.
    ///   - sheetId: The unique identifier for the vocabulary sheet.
    ///   - front: The front term of the vocabulary card.
    ///   - back: The definition or translation of the vocabulary card.
    ///   - addedBy: The user ID of the person who added the card.
    ///   - favorited: Whether the card has been favorited.
    ///   - createdAt: Timestamp of when the card was created.
    ///   - updatedAt: Timestamp of the last update to the card.
    ///   - lastReviewed: The last time the card was reviewed by the user.
    ///   - isSynced: Whether or not the data has been synced to Firestore
    init(id: String,sheetId: String, front: String, back: String, addedBy: String, favorited: Bool, createdAt: Date, updatedAt: Date, lastReviewed: Date? = nil, isSynced: Bool) {
        self.id = id
        self.sheetId = sheetId
        self.front = front
        self.back = back
        self.addedBy = addedBy
        self.favorited = favorited
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastReviewed = lastReviewed
        self.isSynced = isSynced
    }
    
    // MARK: - Send to Firestore
    
    /// Converts the `VocabCardModel` instance into a Firestore-compatible dictionary.
    /// - Returns: A dictionary representation of the `VocabCardModel`.
    func toFireStoreData() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "sheetId": sheetId,
            "front": front,
            "back": back,
            "addedBy": addedBy,
            "favorited": favorited,
            "createdAt": createdAt,
            "updatedAt": updatedAt,
            "isSynced": isSynced,
        ]
        
        if let lastReviewed = lastReviewed {
            data["lastReviewed"] = lastReviewed
        }
        
        return data
    }
    
    // MARK: - Get from Firestore
    
    /// Creates a `VocabCardModel` instance from Firestore data.
    /// - Parameter data: A dictionary containing Firestore data.
    /// - Returns: A `VocabCardModel` instance if the data is valid, otherwise `nil`.
    static func fromFireStoreData(_ data: [String: Any]) -> VocabCardModel? {
        guard let id = data["id"] as? String,
              let sheetId = data["sheetId"] as? String,
              let front = data["front"] as? String,
              let back = data["back"] as? String,
              let addedBy = data["addedBy"] as? String,
              let favorited = data["favorited"] as? Bool,
              let createdAtTimestamp = data["createdAt"] as? Timestamp,
              let updatedAtTimestamp = data["updatedAt"] as? Timestamp,
              let isSynced = data["isSynced"] as? Bool
        else {
            return nil
        }

        let createdAt = createdAtTimestamp.dateValue()
        let updatedAt = updatedAtTimestamp.dateValue()
        let lastReviewed = (data["lastReviewed"] as? Timestamp)?.dateValue()

        return VocabCardModel(id: id, sheetId: sheetId, front: front, back: back, addedBy: addedBy, favorited: favorited, createdAt: createdAt, updatedAt: updatedAt, lastReviewed: lastReviewed, isSynced: isSynced)
    }

    
    // MARK: - toSQLite
    // Will convert VocabCardModel to SQLite data format
    func toSQLite() -> [String: Any] {
        return [
            "id": self.id,
            "sheetId": self.sheetId,
            "front": self.front,
            "back": self.back,
            "addedBy": self.addedBy,
            "favorited": self.favorited ? 1 : 0,
            "createdAt": self.createdAt.timeIntervalSince1970,
            "updatedAt": self.updatedAt.timeIntervalSince1970,
            "lastReviewed": self.lastReviewed?.timeIntervalSince1970 ?? NSNull(),
            "isSynced": self.isSynced,
            
        ]
    }
    
    // MARK: - fromSQLite
    /// Creates a `VocabCardModel` instance from a SQLite-compatible dictionary.
    /// - Parameter data: A dictionary containing SQLite data.
    /// - Returns: A `VocabCardModel` instance if the data is valid, otherwise `nil`.
    static func fromSQLite(_ data: [String: Any]) -> VocabCardModel? {
        guard let id = data["id"] as? String,
              let sheetId = data["sheetId"] as? String,
              let front = data["front"] as? String,
              let back = data["back"] as? String,
              let addedBy = data["addedBy"] as? String,
              let favorited = data["favorited"] as? Int,
              let createdAtTimestamp = data["createdAt"] as? Double,
              let updatedAtTimestamp = data["updatedAt"] as? Double,
              let isSynced = data["isSynced"] as? Bool,
        else {
            return nil
        }
        
        let lastReviewedTimestamp = data["lastReviewed"] as? Double
        let lastReviewed = lastReviewedTimestamp != nil ? Date(timeIntervalSince1970: lastReviewedTimestamp!) : nil
        
        return VocabCardModel(
            id: id,
            sheetId: sheetId,
            front: front,
            back: back,
            addedBy: addedBy,
            favorited: favorited == 1, // Convert from Int (1 or 0)
            createdAt: Date(timeIntervalSince1970: createdAtTimestamp),
            updatedAt: Date(timeIntervalSince1970: updatedAtTimestamp),
            lastReviewed: lastReviewed,
            isSynced: isSynced
        )
    }
}
