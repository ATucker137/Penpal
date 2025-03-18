//
//  VocabCardService.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//

class VocabCardService {
    // MARK: - Set Variables for Firestore
    private let db = Firestore.firestore()
    private let collectionName = "vocabCards"
    
    // MARK: - Create Vocab Card Service
    
    func createVocabCard(vocabCard: VocabCardModel, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try
            db.collection(collectionName).document(vocabCard.id).setData(from: vocabCard) {
                error in
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
    
    func updateCard(vocabCard: VocabCardModel, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try
            db.collection(collectionName).document(vocabCard.id).setData(from: vocabCard, merge: true) { error in
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
    
    func fetchVocabCard(vocabCardId: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        db.collection(collectionName).document(vocabCardId).getDocument {
            snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let snapshot = snapshot, snapshot.nameExists // i think its supposed to be exists
                else {
                    completion(.failure(NSError(domain: "ProfileService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Profile not found."])))
                    return
            }
            do {
                let vocabCard = try snapshot.data(as: VocabCardModel.self) // Decode Firestore document into Profile
                completion(.success(vocabCard))
            } catch let error {
                completion(.failure(error))
            }
        }
        
    }
}
