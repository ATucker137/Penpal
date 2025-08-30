//  VocabSheetModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct VocabSheetModel: Identifiable, Codable {
    
    @DocumentID var id: String? // The Firestore document ID is automatically handled here
    var name: String
    var createdBy: String
    var totalCards: Int
    var lastReviewed: Date?
    var lastUpdated: Date
    var createdAt: Date
    var isSynced: Bool
    
    // An empty initializer is required for Firestore's automatic decoding
    init(id: String? = nil, name: String, createdBy: String, totalCards: Int, lastReviewed: Date?, lastUpdated: Date, createdAt: Date, isSynced: Bool) {
        self.id = id
        self.name = name
        self.createdBy = createdBy
        self.totalCards = totalCards
        self.lastReviewed = lastReviewed
        self.lastUpdated = lastUpdated
        self.createdAt = createdAt
        self.isSynced = isSynced
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

