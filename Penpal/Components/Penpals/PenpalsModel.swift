//
//  PenpalsModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//
import Foundation
import SQLite3
// TODO: - Language need to add
struct PenpalsModel: Codable, Identifiable {
    let id: String // Unique ID for this match request (could be userId + penpalId)
    let userId: String // The user who is sending the request
    let penpalId: String // The potential match
    let firstName: String
    let lastName: String
    let proficiency: String
    let hobbies: [String]
    let goals: String
    let region: String
    var matchScore: Int? // Optional, calculated when ranking matches
    var status: PenpalStatus // Tracks request status
    let isSynced: Bool
    
    // MARK: - Default initializer
    init(userId: String, penpalId: String, firstName: String, lastName: String, proficiency: String, hobbies: [String], goals: String, region: String, matchScore: Int? = nil, status: PenpalStatus = .pending,isSynced: Bool) {
        self.id = "\(userId)_\(penpalId)" // Unique ID for match request - Maybe do this
        self.userId = userId
        self.penpalId = penpalId
        self.firstName = firstName
        self.lastName = lastName
        self.proficiency = proficiency
        self.hobbies = hobbies
        self.goals = goals
        self.region = region
        self.matchScore = matchScore
        self.status = status
        self.isSynced = isSynced
        
    }
    // MARK: - Converts Firestore data into a PenpalsModel instance
    static func fromFireStoreData(_ data: [String: Any]) -> PenpalsModel? {
        guard let userId = data["userId"] as? String,
              let penpalId = data["penpalId"] as? String,
              let firstName = data["firstName"] as? String,
              let lastName = data["lastName"] as? String,
              let proficiency = data["proficiency"] as? String,
              let hobbiesArray = data["hobbies"] as? [Any], // Firestore arrays are [Any]
              let goalsArray = data["goals"] as? [Any], // Ensure goals are stored as an array
              let region = data["region"] as? String,
              let statusString = data["status"] as? String,
              let status = PenpalStatus(rawValue: statusString) // Convert string to enum
        else {
            return nil // TODO: - this should be looked at
        }
        
        let hobbies = hobbiesArray.compactMap { $0 as? String }
        let goals = goalsArray.compactMap { $0 as? String }
        let matchScore = data["matchScore"] as? Int
        let isSynced = data["isSynced"] as? Bool ?? false

        
        return PenpalsModel(
            userId: userId,
            penpalId: penpalId,
            firstName: firstName,
            lastName: lastName,
            proficiency: proficiency,
            hobbies: hobbies,
            goals: goals,
            region: region,
            matchScore: matchScore,
            status: status,
            isSynced: isSynced
        )
    }
    
    // MARK: - Converts PenpalsModel instance into Firestore-friendly dictionary
    func toFireStoreData() -> [String: Any] {
        return [
            "userId": userId,
            "penpalId": penpalId,
            "firstName": firstName,
            "lastName": lastName,
            "proficiency": proficiency,
            "hobbies": hobbies, // Firestore stores arrays natively
            "goals": goals, // Ensuring this remains an array
            "region": region,
            "matchScore": matchScore ?? NSNull(), // Firestore doesn't store `nil`, use `NSNull()`
            "status": status.rawValue, // Store enum as a string
            "isSynced": isSynced
        ]
    }
    // MARK: - Converts PenpalsModel to SQLite format
    func toSQLite() -> [String: Any] {
        return [
            "userId": userId,
            "penpalId": penpalId,
            "firstName": firstName,
            "lastName": lastName,
            "proficiency": proficiency,
            "hobbies": hobbies.joined(separator: ","), // Store as comma-separated string
            "goals": goals.joined(separator: ","), // Store as comma-separated string
            "region": region,
            "matchScore": matchScore ?? NSNull(), // Handle optional Int
            "status": status.rawValue, // Store enum as String
            "isSynced": isSynced
        ]
    }
    
    // MARK: - Converts SQLite data into a PenpalsModel instance
    static func fromSQLite(_ data: [String: Any]) -> PenpalsModel? {
        guard let userId = data["userId"] as? String,
              let penpalId = data["penpalId"] as? String,
              let firstName = data["firstName"] as? String,
              let lastName = data["lastName"] as? String,
              let proficiency = data["proficiency"] as? String,
              let hobbiesString = data["hobbies"] as? String,
              let goalsString = data["goals"] as? String,
              let region = data["region"] as? String,
              let statusString = data["status"] as? String,
              let status = PenpalStatus(rawValue: statusString) // Convert back to enum
        else {
            return nil
        }
        
        let hobbies = hobbiesString.components(separatedBy: ",") // Convert back to array
        let goals = goalsString.components(separatedBy: ",") // Convert back to array
        let matchScore = data["matchScore"] as? Int // Handle optional Int
        let isSynced = data["isSynced"] as? Bool
        
        
        return PenpalsModel(
            userId: userId,
            penpalId: penpalId,
            firstName: firstName,
            lastName: lastName,
            proficiency: proficiency,
            hobbies: hobbies,
            goals: goals,
            region: region,
            matchScore: matchScore,
            status: status,
            isSynced: isSynced
        )
    }
}
    
    

// MARK: - Different Statuses For Penpals
enum PenpalStatus: String, Codable {
    case pending
    case approved
    case declined
}






