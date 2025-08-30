//
//  VocabCardViewModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//
import Foundation
import Combine

class VocabCardViewModel: ObservableObject {

    @Published var vocabCards: [VocabCardModel] = []
    
    private var vocabCardService: VocabCardService
    private var cancellables = Set<AnyCancellable>()
    var isLoading = false
    var errorMessage: String?
    private let category = "vocabCardViewModel"

    
    
    // MARK: - Initalizer -- Will Have to deal with the Vocab Sheet
    init(vocabCardService: VocabCardService) {
        self.vocabCardService = vocabCardService
    }
    
    
    // MARK: - Helper Methods
    
    // MARK: - Fetch Vocab Cards
    func fetchVocabCards(for sheetId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let cards = try await vocabCardService.fetchVocabCards(for: sheetId)
            self.vocabCards = cards
            
            // You can also handle SQLite fetching here if needed, but it's
            // recommended to have the SQLite cache managed at the service layer
            // for offline-first capabilities.
            
            LoggerService.shared.log(.info, "Loaded \(cards.count) vocab cards from Firestore", category: self.category)
        } catch {
            LoggerService.shared.log(.error, "❌ Error fetching vocab cards: \(error.localizedDescription)", category: self.category)
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    
    // MARK: - Edit Vocab Card
    /// Edits an existing vocabulary card.
    /// - Parameters:
    ///   - card: The card to be updated.
    ///   - sheetId: The ID of the vocab sheet.
    func editVocabCard(card: VocabCardModel, sheetId: String) async {
        guard let userId = auth.currentUser?.uid else {
            LoggerService.shared.log(.error, "❌ User not logged in", category: self.category)
            self.errorMessage = "You must be logged in to edit this card."
            return
        }

        guard card.addedBy == userId else {
            LoggerService.shared.log(.error, "❌ Unauthorized: User cannot edit this card", category: self.category)
            self.errorMessage = "You are not authorized to edit this card."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await vocabCardService.updateVocabCard(card, sheetId: sheetId)
            LoggerService.shared.log(.info, "✅ Successfully updated vocab card", category: self.category)
        } catch {
            LoggerService.shared.log(.error, "❌ Error updating vocab card: \(error.localizedDescription)", category: self.category)
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Edit Card Front
    /// Updates the front of a vocabulary card.
    /// - Parameters:
    ///   - card: The card to update.
    ///   - newFront: The new text for the card's front.
    ///   - sheetId: The ID of the vocab sheet.
    func editVocabCardFront(card: VocabCardModel, newFront: String, sheetId: String) async {
        guard isValidCardText(newFront) else {
            self.errorMessage = "Invalid card front text."
            return
        }
        
        var updatedCard = card
        updatedCard.front = newFront.trimmingCharacters(in: .whitespacesAndNewlines)
        
        await editVocabCard(card: updatedCard, sheetId: sheetId)
    }
    
    // MARK: - Edit Card Back
    /// Updates the back of a vocabulary card.
    /// - Parameters:
    ///   - card: The card to update.
    ///   - newBack: The new text for the card's back.
    ///   - sheetId: The ID of the vocab sheet.
    func editVocabCardBack(card: VocabCardModel, newBack: String, sheetId: String) async {
        guard isValidCardText(newBack) else {
            self.errorMessage = "Invalid card back text."
            return
        }
        
        var updatedCard = card
        updatedCard.back = newBack.trimmingCharacters(in: .whitespacesAndNewlines)
        
        await editVocabCard(card: updatedCard, sheetId: sheetId)
    }
    
    // MARK: - Add Vocab Card
    /// Adds a new vocabulary card to a specific sheet.
    /// - Parameters:
    ///   - sheetId: The ID of the vocab sheet.
    ///   - front: The text for the front of the card.
    ///   - back: The text for the back of the card.
    func addVocabCard(to sheetId: String, front: String, back: String) async {
        guard let userId = auth.currentUser?.uid else {
            LoggerService.shared.log(.error, "❌ User not logged in", category: self.category)
            self.errorMessage = "You must be logged in to add a card."
            return
        }
        
        guard isValidCardText(front), isValidCardText(back) else {
            LoggerService.shared.log(.error, "❌ Invalid vocab card content", category: self.category)
            self.errorMessage = "Card text is invalid."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let newCard = VocabCardModel(
            id: UUID().uuidString,
            front: front.trimmingCharacters(in: .whitespacesAndNewlines),
            back: back.trimmingCharacters(in: .whitespacesAndNewlines),
            addedBy: userId,
            addedAt: Date(),
            favorited: false
        )
        
        do {
            try await vocabCardService.addVocabCard(to: sheetId, card: newCard)
            LoggerService.shared.log(.info, "✅ Successfully added vocab card", category: self.category)
        } catch {
            LoggerService.shared.log(.error, "❌ Error adding vocab card: \(error.localizedDescription)", category: self.category)
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Delete Vocab Card
    /// Deletes a vocabulary card from a specific sheet.
    /// - Parameters:
    ///   - cardId: The ID of the card to delete.
    ///   - sheetId: The ID of the vocab sheet.
    func deleteVocabCard(cardId: String, sheetId: String) async {
        guard let userId = auth.currentUser?.uid else {
            LoggerService.shared.log(.error, "❌ User not logged in", category: self.category)
            self.errorMessage = "You must be logged in to delete this card."
            return
        }
        
        guard let card = vocabCards.first(where: { $0.id == cardId }), card.addedBy == userId else {
            LoggerService.shared.log(.error, "❌ Unauthorized: User cannot delete this card", category: self.category)
            self.errorMessage = "You are not authorized to delete this card."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await vocabCardService.deleteVocabCard(cardId, from: sheetId)
            LoggerService.shared.log(.info, "✅ Successfully deleted vocab card", category: self.category)
        } catch {
            LoggerService.shared.log(.error, "❌ Error deleting vocab card: \(error.localizedDescription)", category: self.category)
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }

    // MARK: - Favorite Vocab Card
    /// Toggles the favorite status of a vocab card.
    /// - Parameters:
    ///   - card: The card to be updated.
    ///   - sheetId: The ID of the vocab sheet.
    func favoriteVocabCard(card: VocabCardModel, sheetId: String) async {
        var updatedCard = card
        updatedCard.favorited.toggle()
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await vocabCardService.updateVocabCard(updatedCard, sheetId: sheetId)
            LoggerService.shared.log(.info, "✅ Successfully updated favorite status", category: self.category)
        } catch {
            LoggerService.shared.log(.error, "❌ Error favoriting vocab card: \(error.localizedDescription)", category: self.category)
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Validation Helpers
    private func isValidCardText(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let isValid = !trimmed.isEmpty && trimmed.count <= 100
        
        if !isValid {
            LoggerService.shared.log(.error, "❌ Invalid card text: \(text)", category: self.category)
        }
        
        return isValid
    }
    
    // Swipe to the next Vocab Card? Maybe within sheet
}
