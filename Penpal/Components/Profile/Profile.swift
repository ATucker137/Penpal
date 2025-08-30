//
//  Profile.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Profile: Codable, Identifiable {
    
    // MARK: - Properties
    @DocumentID var id: String?
    var firstName: String
    var lastName: String
    var email: String
    var region: String
    var country: String
    var nativeLanguage: Language
    var targetLanguage: Language
    var targetLanguageProficiency: LanguageProficiency
    var goal: Goals?
    var hobbies: [Hobbies]
    var profileImageURL: String
    var createdAt: Date
    var updatedAt: Date
    var notificationSettings: NotificationSettings
    var isSynced: Bool

    // MARK: - Initializer
    init(id: String? = nil, firstName: String, lastName: String, email: String, region: String, country: String, nativeLanguage: Language, targetLanguage: Language, targetLanguageProficiency: LanguageProficiency, goal: Goals?, hobbies: [Hobbies], profileImageURL: String, createdAt: Date, updatedAt: Date, notificationSettings: NotificationSettings, isSynced: Bool) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.region = region
        self.country = country
        self.nativeLanguage = nativeLanguage
        self.targetLanguage = targetLanguage
        self.targetLanguageProficiency = targetLanguageProficiency
        self.goal = goal
        self.hobbies = hobbies
        self.profileImageURL = profileImageURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.notificationSettings = notificationSettings
        self.isSynced = isSynced
    }
    
    // MARK: - SQLite Data Conversion
    func toSQLite() -> [String: Any] {
        let encodedGoals = (try? JSONEncoder().encode(goal)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        let encodedHobbies = (try? JSONEncoder().encode(hobbies.map { $0.rawValue })).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"

        return [
            "id": id ?? UUID().uuidString,
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "region": region,
            "country": country,
            "nativeLanguage": nativeLanguage.rawValue,
            "targetLanguage": targetLanguage.rawValue,
            "targetLanguageProficiency": targetLanguageProficiency.rawValue,
            "goal": encodedGoals,
            "hobbies": encodedHobbies,
            "profileImageURL": profileImageURL,
            "createdAt": createdAt.timeIntervalSince1970,
            "updatedAt": updatedAt.timeIntervalSince1970,
            "notificationSettings_notify1hBefore": notificationSettings.notify1HourBefore ? 1 : 0,
            "notificationSettings_notify6hBefore": notificationSettings.notify6HoursBefore ? 1 : 0,
            "notificationSettings_notify24hBefore": notificationSettings.notify24HoursBefore ? 1 : 0,
            "notificationSettings_allowEmailNotifications": notificationSettings.allowEmailNotifications ? 1 : 0,
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
              let goalString = data["goal"] as? String,
              let hobbiesString = data["hobbies"] as? String,
              let profileImageURL = data["profileImageURL"] as? String,
              let createdAtTimestamp = data["createdAt"] as? Double,
              let updatedAtTimestamp = data["updatedAt"] as? Double,
              let isSyncedInt = data["isSynced"] as? Int
        else {
            return nil
        }
        
        let notify1h = (data["notificationSettings_notify1hBefore"] as? Int ?? 0) != 0
        let notify6h = (data["notificationSettings_notify6hBefore"] as? Int ?? 0) != 0
        let notify24h = (data["notificationSettings_notify24hBefore"] as? Int ?? 0) != 0
        let emailAllowed = (data["notificationSettings_allowEmailNotifications"] as? Int ?? 1) != 0

        let settings = NotificationSettings(
            allowEmailNotifications: emailAllowed,
            notify1HourBefore: notify1h,
            notify6HoursBefore: notify6h,
            notify24HoursBefore: notify24h
        )

        do {
            let goalData = goalString.data(using: .utf8) ?? Data()
            let goal = try JSONDecoder().decode(Goals.self, from: goalData)

            let hobbiesData = hobbiesString.data(using: .utf8) ?? Data()
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
                goal: goal,
                hobbies: hobbies,
                profileImageURL: profileImageURL,
                createdAt: Date(timeIntervalSince1970: createdAtTimestamp),
                updatedAt: Date(timeIntervalSince1970: updatedAtTimestamp),
                notificationSettings: settings,
                isSynced: isSyncedInt == 1
            )
        } catch {
            print("❌ Failed to decode profile goal or hobbies: \(error)")
            return nil
        }
    }
}
