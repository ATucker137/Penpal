//
//  Hobbies.swift
//  Penpal
//
//  Created by Austin William Tucker on 12/5/24.
//

import Foundation

class Hobbies: Codable,Identifiable,Equatable {
    var id: String
    var name: String
    
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
    
    
    // Equatable Conformance
    static func == (lhs: Hobby, rhs: Hobby) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }
    
    static let predefinedHobbies: [Hobbies] = [
        Hobbies(id: "1", name: "Sports"),
        Hobbies(id: "2", name: "Movies and Entertainment"),
        Hobbies(id: "3", name: "Food and Cooking"),
        Hobbies(id: "4", name: "Reading and Writing"),
        Hobbies(id: "5", name: "Music"),
        Hobbies(id: "6", name: "Technology and Gaming"),
        Hobbies(id: "7", name: "Art and Crafts"),
        Hobbies(id: "8", name: "Outdoor Activities")
        Hobbies(id: "9", name: "Animals and Pets")
        Hobbies(id: "10", name: "Science")
        ]

}
