//
//  Quiz.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//

// MARK: - Quiz Class - Model for Quiz in the MVVM Structure
class Quiz: Codable, Identifiable {
    
    // MARK: - Properties
    var id: String
    var userId: String
    var title: String
    var description: String
    var createdBy: String
    var createdAt: Date
    var updatedAt: Date
    var questions: [Questions]
    
    //MARK: - Initializer
    init(id: String, userId: String, title: String, description: String, createdBy: String, createdAt: Date, updatedAt: Date, questions: [Questions]) {
        self.id = id
        self.userId = userId
        self.title = title
        self.description = description
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.questions = questions
    }
    
    // MARK: - Method taking data from Firestore and converting to a Quiz
    static func fromFireStoreData(_ data: [String: Any]) -> Quiz {
        guard let id = data["id"] as? String,
              let userId = data["userId"] as? String,
              let title = data["title"] as? String,
              let description = data["description"] as? String,
              let createdBy = data["createdBy"] as? String,
              let createdAt = data["createdAt"] as? Date,
              let updatedAt = data["updatedAt"] as? Date,
              let questions = data["questions"] as? [Questions] else {
            return nil
        }
        return Quiz(id: id, userId: userId, title: title, description: description, createdBy: createdBy, createdAt: createdAt, updatedAt: updatedAt, questions: questions)
    }
    
    // MARK: - Method for taking the Quiz Model and putting into FireStore
    func toFireStoreData() -> [String: Any]{
        
    }
    
    
    
}
