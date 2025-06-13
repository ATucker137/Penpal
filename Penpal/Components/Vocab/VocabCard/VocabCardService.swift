//
//  VocabCardService.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//
import Foundation
import FirebaseFirestore
import Combine

class VocabCardService {
    private var db = Firestore.firestore()
    
    // MARK: - Fetch Vocab Cards for a specific Sheet
    func fetchVocabCards(for sheetId: String, completion: @escaping (Result<[VocabCardModel], Error>) -> Void) {
        db.collection("vocabSheets")
            .document(sheetId)
            .collection("vocabCards")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.failure(NSError(domain: "VocabCardService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No vocab cards found."])))
                    return
                }
                
                let cards = documents.compactMap { document -> VocabCardModel? in
                    try? document.data(as: VocabCardModel.self)
                }
                completion(.success(cards))
            }
    }
    
    // MARK: - Add a New Vocab Card
    func addVocabCard(to sheetId: String, card: VocabCardModel) -> AnyPublisher<Void, Error> {
        let cardData = try? Firestore.Encoder().encode(card)
        
        return Future { promise in
            self.db.collection("vocabSheets")
                .document(sheetId)
                .collection("vocabCards")
                .addDocument(data: cardData ?? [:]) { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Update a Vocab Card
    func updateVocabCard(_ card: VocabCardModel, sheetId: String) -> AnyPublisher<Void, Error> {
        let cardData = try? Firestore.Encoder().encode(card)
        
        return Future { promise in
            self.db.collection("vocabSheets")
                .document(sheetId)
                .collection("vocabCards")
                .document(card.id)
                .setData(cardData ?? [:], merge: true) { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Delete a Vocab Card
    func deleteVocabCard(_ cardId: String, from sheetId: String) -> AnyPublisher<Void, Error> {
        return Future { promise in
            self.db.collection("vocabSheets")
                .document(sheetId)
                .collection("vocabCards")
                .document(cardId)
                .delete { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
        }
        .eraseToAnyPublisher()
    }
}
