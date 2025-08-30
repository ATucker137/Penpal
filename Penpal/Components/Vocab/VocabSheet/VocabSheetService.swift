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
    private let category = "vocabSheet Service"

    
    // MARK: - Create Vocab Sheet in Firestore
    /// - Parameter vocabSheet: The `VocabSheetModel` object to be created.
    func createVocabSheet(vocabSheet: VocabSheetModel) async throws {
        do {
            try await db.collection(collectionName).document(vocabSheet.id).setData(from: vocabSheet)
            LoggerService.shared.log(.info, "✅ Created vocab sheet with id: \(vocabSheet.id)", category: self.category)
        } catch {
            LoggerService.shared.log(.error, "❌ Failed to create vocab sheet: \(error.localizedDescription)", category: self.category)
            throw error
        }
    }
    
    // MARK: - Update Vocab Sheet
    /// - Parameter vocabSheet: The `VocabSheetModel` object containing the updated data.
    func updateVocabSheet(vocabSheet: VocabSheetModel) async throws {
        do {
            try await db.collection(collectionName).document(vocabSheet.id).setData(from: vocabSheet, merge: true)
            LoggerService.shared.log(.info, "✅ Updated vocab sheet with id: \(vocabSheet.id)", category: self.category)
        } catch {
            LoggerService.shared.log(.error, "❌ Failed to update vocab sheet: \(error.localizedDescription)", category: self.category)
            throw error
        }
    }
    
    // MARK: - Fetch Vocab Sheet
    /// - Returns: The fetched `VocabSheetModel`.
    func fetchVocabSheet(vocabSheetId: String) async throws -> VocabSheetModel {
        do {
            let snapshot = try await db.collection(collectionName).document(vocabSheetId).getDocument()
            
            guard snapshot.exists else {
                LoggerService.shared.log(.error, "❌ Vocab sheet not found for id: \(vocabSheetId)", category: self.category)
                throw FirestoreError.documentNotFound
            }
            
            let vocabSheet = try snapshot.data(as: VocabSheetModel.self)
            LoggerService.shared.log(.info, "✅ Successfully fetched vocab sheet: \(vocabSheetId)", category: self.category)
            return vocabSheet
        } catch {
            LoggerService.shared.log(.error, "❌ Error fetching vocab sheet: \(error.localizedDescription)", category: self.category)
            throw error
        }
    }
    
    // MARK: - Delete Vocab Sheet
    func deleteVocabSheet(sheetId: String) async throws {
        do {
            try await db.collection(collectionName).document(sheetId).delete()
            LoggerService.shared.log(.info, "✅ Deleted vocab sheet with id: \(sheetId)", category: self.category)
        } catch {
            LoggerService.shared.log(.error, "❌ Failed to delete vocab sheet: \(error.localizedDescription)", category: self.category)
            throw error
        }
    }
    
    enum FirestoreError: Error {
        case documentNotFound
    }
}
