//
//  Profile.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//

import Foundation
import FirebaseFirestore
import SQLite3

class Profile: Codable, Identifiable {
    
    // MARK: - Properties
    var id: String
    var firstName: String
    var lastName: String
    var email: String
    var region: String
    var country: String
    var nativeLanguage: Language
    var targetLanguage: Language
    var targetLanguageProficiency: LanguageProficiency
    var goals: [String]
    var hobbies: [Hobbies]
    var profileImageURL: String
    var createdAt: Date
    var updatedAt: Date
    var isSynced: Bool

    // MARK: - Initializer
    init(id: String, firstName: String, lastName: String, email: String, region: String, country: String, nativeLanguage: Language, targetLanguage: Language, targetLanguageProficiency: LanguageProficiency, goals: [String], hobbies: [Hobbies], profileImageURL: String, createdAt: Date, updatedAt: Date, isSynced: Bool) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.region = region
        self.country = country
        self.nativeLanguage = nativeLanguage
        self.targetLanguage = targetLanguage
        self.targetLanguageProficiency = targetLanguageProficiency
        self.goals = goals
        self.hobbies = hobbies
        self.profileImageURL = profileImageURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isSynced = isSynced
    }
    
    // MARK: - Firestore Data Conversion
    static func fromFireStoreData(_ data: [String: Any]) -> Profile? {
        guard let id = data["id"] as? String,
              let firstName = data["firstName"] as? String,
              let lastName = data["lastName"] as? String,
              let email = data["email"] as? String,
              let region = data["region"] as? String,
              let country = data["country"] as? String,
              let nativeLanguageRaw = data["nativeLanguage"] as? String,
              let targetLanguageRaw = data["targetLanguage"] as? String,
              let targetLanguageProficiencyRaw = data["targetLanguageProficiency"] as? String,
              let goals = data["goals"] as? [String],
              let hobbiesRaw = data["hobbies"] as? [String],
              let profileImageURL = data["profileImageURL"] as? String,
              let createdAtTimestamp = data["createdAt"] as? Timestamp,
              let updatedAtTimestamp = data["updatedAt"] as? Timestamp,
              let isSynced = data["isSynced"] as? Bool
        else {
            return nil
        }

        let nativeLanguage = Language(rawValue: nativeLanguageRaw) ?? .english
        let targetLanguage = Language(rawValue: targetLanguageRaw) ?? .english
        let targetLanguageProficiency = LanguageProficiency(rawValue: targetLanguageProficiencyRaw) ?? .beginner
        let hobbies = hobbiesRaw.compactMap { Hobbies(rawValue: $0) }

        return Profile(id: id,
                       firstName: firstName,
                       lastName: lastName,
                       email: email,
                       region: region,
                       country: country,
                       nativeLanguage: nativeLanguage,
                       targetLanguage: targetLanguage,
                       targetLanguageProficiency: targetLanguageProficiency,
                       goals: goals,
                       hobbies: hobbies,
                       profileImageURL: profileImageURL,
                       createdAt: createdAtTimestamp.dateValue(),
                       updatedAt: updatedAtTimestamp.dateValue(),
                       isSynced: isSynced)
    }
    
    func toFireStoreData() -> [String: Any] {
        return [
            "id": id,
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "region": region,
            "country": country,
            "nativeLanguage": nativeLanguage.rawValue,
            "targetLanguage": targetLanguage.rawValue,
            "targetLanguageProficiency": targetLanguageProficiency.rawValue,
            "goals": goals,
            "hobbies": hobbies.map { $0.rawValue },
            "profileImageURL": profileImageURL,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt),
            "isSynced": isSynced
        ]
    }

    // MARK: - SQLite Data Conversion
    func toSQLite() -> [String: Any] {
        let encodedGoals = (try? JSONEncoder().encode(goals)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        let encodedHobbies = (try? JSONEncoder().encode(hobbies.map { $0.rawValue })).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"

        return [
            "id": id,
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "region": region,
            "country": country,
            "nativeLanguage": nativeLanguage.rawValue,
            "targetLanguage": targetLanguage.rawValue,
            "targetLanguageProficiency": targetLanguageProficiency.rawValue,
            "goals": encodedGoals,
            "hobbies": encodedHobbies,
            "profileImageURL": profileImageURL,
            "createdAt": createdAt.timeIntervalSince1970,
            "updatedAt": updatedAt.timeIntervalSince1970,
            "isSynced": isSynced ? 1 : 0
        ]
    }


    static func fromSQLite(_ data: [String: Any]) -> Profile? {
        guard let id = data["id"] as? String,
              let firstName = data["firstName"] as? String,
              let lastName = data["lastName"] as? String,
              let email = data["email"] as? String,
              let region = data["region"] as? String,
              let country = data["country"] as? String,
              let nativeLanguageRaw = data["nativeLanguage"] as? String,
              let targetLanguageRaw = data["targetLanguage"] as? String,
              let targetLanguageProficiencyRaw = data["targetLanguageProficiency"] as? String,
              let goalsString = data["goals"] as? String,
              let hobbiesString = data["hobbies"] as? String,
              let profileImageURL = data["profileImageURL"] as? String,
              let createdAtTimestamp = data["createdAt"] as? Double,
              let updatedAtTimestamp = data["updatedAt"] as? Double,
              let isSyncedInt = data["isSynced"] as? Int
        else {
            return nil
        }

        do {
            guard let goalsData = goalsString.data(using: .utf8),
                  let hobbiesData = hobbiesString.data(using: .utf8) else {
                return nil
            }

            let goals = try JSONDecoder().decode([String].self, from: goalsData)
            let hobbiesRaw = try JSONDecoder().decode([String].self, from: hobbiesData)
            let hobbies = hobbiesRaw.compactMap { Hobbies(rawValue: $0) }

            return Profile(
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
                createdAt: Date(timeIntervalSince1970: createdAtTimestamp),
                updatedAt: Date(timeIntervalSince1970: updatedAtTimestamp),
                isSynced: isSyncedInt == 1
            )
        } catch {
            print("❌ Failed to decode profile goals or hobbies: \(error)")
            return nil
        }
    }
}
