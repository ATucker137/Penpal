//
//  Profile.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//

//This is the Profile Model in the MVVM Structure

import Foundation


// NOTE: Should createdAt and updatedAt be String or set to date, i think setting to strings would be easier
// NOTE: Uses JSONDecoder to decode languages and hobbies from nested dictionaries.

class Profile: Codable, Identifiable {
    
    // MARK: - Properties
    var id: String
    var firstName: String
    var lastName: String
    var email: String
    var region: String
    var country: String
    var languages: [LanguageProficiency]
    var goals: [String]
    var hobbies: [Hobbies]
    var profileImageURL: String
    var createdAt: String
    var updatedAt: String

    
    // MARK: - Initializer
    init(
        id: String,
        firstName: String,
        lastName: String,
        email: String,
        region: String,
        country: String,
        languages: [LanguageProficiency],
        goals: [String],
        hobbies: [Hobbies],
        profileImageURL: String,
        createdAt: String,
        updatedAt: String
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.region = region
        self.country = country
        self.languages = languages
        self.goals = goals
        self.hobbies = hobbies
        self.profileImageURL = profileImageURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Takes Data From Firestore and Turns into Profile
    // made static because it doesnt rely on existing existence
    static func fromFireStoreData(_ data: [String: Any]) -> Profile {
        guard let id = data["id"] as? String,
              let firstName = data["firstName"] as? String,
              let lastName = data["lastName"] as? String,
              let email = data["email"] as? String,
              let region = data["region"] as? String,
              let country = data["country"] as? String,
              let languages = data["languages"] as? [LanguageProficiency],
              let goals = data["goals"] as? [String],
              let hobbies = data["hobbies"] as? [Hobbies],
              let profileImageURL = data["profileImageURL"] as? String,
              let createdAt = data["createdAt"] as? String,
              let updatedAt = data["updatedAt"] as? String else {
            return nil
        }
        return Profile(id: id, firstName: firstName, lastName: lastName, email: email, region: region, country: country, languages: languages, goals: goals, hobbies: hobbies, profileImageURL: profileImageURL, createdAt: createdAt, updatedAt: updatedAt)
    }
    
    // MARK: - Takes Profile data and puts into Firestore
    func toFireStoreData() -> [String: Any] {
        return [
            "id" : id,
            "firstName" : firstName,
            "lastName" : lastName,
            "email" : email,
            "region" : region,
            "country" : country,
            "languages" : languages,
            "goals" : goals,
            "hobbies" : hobbies,
            "profileImageURL" : profileImageURL,
            "createdAt" : createdAt,
            "updatedAt" : updatedAt,
        ]
    }
    
}
