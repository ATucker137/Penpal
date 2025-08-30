//
//  PenpalsModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//
import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import SQLite3

// TODO: - Language need to add
struct PenpalsModel: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String // The user who is sending the request
    var penpalId: String // The potential match
    var firstName: String
    var lastName: String
    var proficiency: LanguageProficiency
    var hobbies: [Hobbies]
    var goal: Goals?
    var region: String
    var matchScore: Int? // Optional, calculated when ranking matches
    var status: PenpalStatus // Tracks request status
    var profileImageURL: String
    var isSynced: Bool
    
    // MARK: - Default initializer
    init(id: String? = nil, userId: String, penpalId: String, firstName: String, lastName: String, proficiency: LanguageProficiency, hobbies: [Hobbies], goal: Goals?, region: String, matchScore: Int? = nil, status: PenpalStatus = .pending, profileImageURL: String, isSynced: Bool) {
        self.id = id
        self.userId = userId
        self.penpalId = penpalId
        self.firstName = firstName
        self.lastName = lastName
        self.proficiency = proficiency
        self.hobbies = hobbies
        self.goal = goal
        self.region = region
        self.matchScore = matchScore
        self.status = status
        self.profileImageURL = profileImageURL
        self.isSynced = isSynced
        
    }
    
    // MARK: - Converts PenpalsModel to SQLite format
    func toSQLite() -> [String: Any] {
        let encoder = JSONEncoder()
        let proficiencyData = try? encoder.encode(proficiency)
        let proficiencyString = String(data: proficiencyData ?? Data(), encoding: .utf8) ?? ""
        
        // Encode single optional goal to JSON string
        let encodedGoal = (try? encoder.encode(goal)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
        
        return [
            "id": id ?? "\(userId)_\(penpalId)", // Using a fallback ID for SQLite
            "userId": userId,
            "penpalId": penpalId,
            "firstName": firstName,
            "lastName": lastName,
            "proficiency": proficiencyString,
            "hobbies": hobbies.map { $0.id }.joined(separator: ","),
            "goal": encodedGoal,
            "region": region,
            "matchScore": matchScore ?? NSNull(),
            "status": status.rawValue,
            "profileImageURL": profileImageURL,
            "isSynced": isSynced
        ]
    }
    
    
    // MARK: - Converts SQLite data into a PenpalsModel instance
    static func fromSQLite(_ data: [String: Any]) -> PenpalsModel? {
        let decoder = JSONDecoder()
        
        guard let proficiencyString = data["proficiency"] as? String,
              let proficiencyData = proficiencyString.data(using: .utf8),
              let proficiency = try? decoder.decode(LanguageProficiency.self, from: proficiencyData),
              let id = data["id"] as? String,
              let userId = data["userId"] as? String,
              let penpalId = data["penpalId"] as? String,
              let firstName = data["firstName"] as? String,
              let lastName = data["lastName"] as? String,
              let hobbiesString = data["hobbies"] as? String,
              let goalString = data["goal"] as? String,
              let region = data["region"] as? String,
              let statusString = data["status"] as? String,
              let profileImageURL = data["profileImageURL"] as? String,
              let status = PenpalStatus(rawValue: statusString)
        else {
            return nil
        }
        
        let hobbyIds = hobbiesString.components(separatedBy: ",")
        let hobbies = hobbyIds.compactMap { id in
            Hobbies.predefinedHobbies.first(where: { $0.id == id })
        }
        
        // Decode single optional goal from JSON string
        let goalData = goalString.data(using: .utf8) ?? Data()
        let goal = try? decoder.decode(Goals.self, from: goalData)
        
        let matchScore = data["matchScore"] as? Int
        let isSynced = data["isSynced"] as? Int == 1
        
        return PenpalsModel(
            id: id,
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
    }
}
