//
//  QuizService.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
class QuizService {
    
    private let db = Firestore.firestore()
    private let collectionName = "quizzes"
    
    // MARK: - Fetch Quiz
    func fetchQuiz(quiz: Quiz, completion: @escaping (Result<Void, Error>) -> Void) {
        
        let documentReference = db.collection(collectionName).document(quiz.id)
    
        
    }
    
    // MARK: - Create Quiz
    func createQuiz(quiz: Quiz, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let documentReference = db.collection(collectionName).document(quiz.id)
            
            try documentReference.setData(from: quiz) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
                
            }
            catch let error {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Delete Quiz
    func deleteQuiz(quiz: Quiz, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let documentReference = db.collection(collectionName).document(quiz.id)
            try documentReference.delete { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
                
            }
        } catch let error {
            completion(.failure(error))
        }
    
    }
    
    // MARK: - Update Quiz
    func updateQuiz(quiz: Quiz, completion: @escaping (Result<Void, Error>) -> Void) {
        
        do {
            let documentReference = db.collection(collectionName).document(quiz.id)
            try documentReference.setData(from: quiz, merge: true) { error in
                
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch let error {
            completion(.failure(error))
        }
    }
}
