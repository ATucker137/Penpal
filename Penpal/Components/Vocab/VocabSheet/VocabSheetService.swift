//
//  VocabSheetService.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

class VocabSheetService {
    // MARK: - Firestore Reference
    private let db = Firestore.firestore()
    private let collectionName = "vocabSheets"
    
    // MARK: - Create Vocab Sheet
    func createVocabSheet(vocabSheet: VocabSheetModel, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try db.collection(collectionName).document(vocabSheet.id).setData(from: vocabSheet) { error in
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
    
    // MARK: - Update Vocab Sheet
    func updateVocabSheet(vocabSheet: VocabSheetModel, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try db.collection(collectionName).document(vocabSheet.id).setData(from: vocabSheet, merge: true) { error in
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
    
    // MARK: - Fetch Vocab Sheet
    func fetchVocabSheet(vocabSheetId: String, completion: @escaping (Result<VocabSheetModel, Error>) -> Void) {
        db.collection(collectionName).document(vocabSheetId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                completion(.failure(NSError(domain: "VocabSheetService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Vocab sheet not found."])))
                return
            }
            
            do {
                let vocabSheet = try snapshot.data(as: VocabSheetModel.self) // Decode Firestore document into model
                completion(.success(vocabSheet))
            } catch let error {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Delete Vocab Sheet
    func deleteVocabSheet(sheetId: String, userId: String) {
        guard let sheet = vocabSheets.first(where: { $0.id == sheetId }), sheet.createdBy == userId else {
            print("❌ Unauthorized: User cannot delete this sheet")
            return
        }

        vocabSheetService.deleteVocabSheet(sheetId)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Error deleting vocab sheet: \(error.localizedDescription)")
                }
            }, receiveValue: {
                print("✅ Successfully deleted vocab sheet")
            })
            .store(in: &cancellables)
    }


}
