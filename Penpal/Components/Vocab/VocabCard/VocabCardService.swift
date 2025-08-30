//
//  VocabCardService.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//
import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import Combine

class VocabCardService {
    private var db = Firestore.firestore()
    private let category = "VocabCard Service"

    // MARK: - Fetch Vocab Cards for a specific Sheet
    /// Fetches all vocabulary cards for a given vocabulary sheet.
    /// - Parameter sheetId: The ID of the vocabulary sheet.
    /// - Returns: An array of `VocabCardModel` objects.
    func fetchVocabCards(for sheetId: String) async throws -> [VocabCardModel] {
        do {
            let snapshot = try await db.collection("vocabSheets")
                .document(sheetId)
                .collection("vocabCards")
                .getDocuments()

            // Map the documents to the VocabCardModel
            let cards = try snapshot.documents.compactMap { document in
                try document.data(as: VocabCardModel.self)
            }

            LoggerService.shared.log(.info, "✅ Successfully fetched \(cards.count) vocab cards for sheetId: \(sheetId)", category: self.category)
            return cards
        } catch {
            LoggerService.shared.log(.error, "❌ Failed to fetch vocab cards for sheetId: \(sheetId) — \(error.localizedDescription)", category: self.category)
            throw error
        }
    }
    
    // MARK: - Add a New Vocab Card
    /// Adds a new vocabulary card to a specific sheet.
    /// - Parameters:
    ///   - card: The `VocabCardModel` object to be added.
    ///   - sheetId: The ID of the vocabulary sheet.
    func addVocabCard(to sheetId: String, card: VocabCardModel) async throws {
        do {
            let _ = try await db.collection("vocabSheets")
                .document(sheetId)
                .collection("vocabCards")
                .addDocument(from: card)

            LoggerService.shared.log(.info, "✅ Added vocab card to sheetId: \(sheetId)", category: self.category)
        } catch {
            LoggerService.shared.log(.error, "❌ Failed to add vocab card to sheetId: \(sheetId) — \(error.localizedDescription)", category: self.category)
            throw error
        }
    }
    
    // MARK: - Update a Vocab Card
    /// Updates an existing vocabulary card in a specific sheet.
    /// - Parameters:
    ///   - card: The `VocabCardModel` object containing the updated data.
    ///   - sheetId: The ID of the vocabulary sheet.
    func updateVocabCard(_ card: VocabCardModel, sheetId: String) async throws {
        do {
            try await db.collection("vocabSheets")
                .document(sheetId)
                .collection("vocabCards")
                .document(card.id)
                .setData(from: card, merge: true)

            LoggerService.shared.log(.info, "✅ Updated vocab card \(card.id) in sheetId: \(sheetId)", category: self.category)
        } catch {
            LoggerService.shared.log(.error, "❌ Failed to update vocab card \(card.id) in sheetId: \(sheetId) — \(error.localizedDescription)", category: self.category)
            throw error
        }
    }
    
    // MARK: - Delete a Vocab Card
    /// Deletes a vocabulary card from a specific sheet.
    /// - Parameters:
    ///   - cardId: The ID of the vocabulary card to delete.
    ///   - sheetId: The ID of the vocabulary sheet.
    func deleteVocabCard(_ cardId: String, from sheetId: String) async throws {
        do {
            try await db.collection("vocabSheets")
                .document(sheetId)
                .collection("vocabCards")
                .document(cardId)
                .delete()

            LoggerService.shared.log(.info, "✅ Deleted vocab card \(cardId) from sheetId: \(sheetId)", category: self.category)
        } catch {
            LoggerService.shared.log(.error, "❌ Failed to delete vocab card \(cardId) from sheetId: \(sheetId) — \(error.localizedDescription)", category: self.category)
            throw error
        }
    }
}
