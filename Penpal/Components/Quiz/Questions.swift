//
//  Questions.swift
//  Penpal
//
//  Created by Austin William Tucker on 12/14/24.
//

class Questions: Codable, Identifiable {
    var question: String
    var answer: String
    
    
    init(question: String, answer: String) {
        self.question = question
        self.answer = answer
    }
    
    
    static let questionType: [String] = [
        
        "Multiple Choice",
    ]
    
    
    
    // Method should also be there for identifying correctness
    
    
    
}
