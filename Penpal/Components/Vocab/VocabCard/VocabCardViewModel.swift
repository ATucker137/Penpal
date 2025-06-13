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
    
    
    // MARK: - Initalizer -- Will Have to deal with the Vocab Sheet
    init(vocabCardService: VocabCardService) {
            self.vocabCardService = vocabCardService
        }
    
    
    // MARK: - Helper Methods
    
    // MARK: - Fetch Vocab Cards
    func fetchVocabCards(for sheetId: String) {
            vocabCardService.fetchVocabCards(for: sheetId) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let cards):
                        self?.vocabCards = cards
                        
                        // Fetch each card from SQLite as well
                        for card in cards {
                            if let sqliteCard = self?.sqliteManager.fetchVocabCard(sheetId: sheetId, id: card.id) {
                                // Process or store the sqliteCard if necessary
                                print("Fetched card from SQLite: \(sqliteCard)")
                            }
                        }
                        
                    case .failure(let error):
                        print("❌ Error fetching vocab cards: \(error.localizedDescription)")
                }
            }
        }
    }
    
    
    // MARK: - Edit Vocab Card
    func editVocabCard(card: VocabCardModel, userId: String) {
        guard card.addedBy == userId else {
            print("❌ Unauthorized: User cannot edit this card")
            return
        }
        
        vocabCardService.updateVocabCard(card)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Error updating vocab card: \(error.localizedDescription)")
                }
            }, receiveValue: {
                print("✅ Successfully updated vocab card")
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Edit Card Front
    func editVocabCardFront(card: VocabCardModel, newFront: String, userId: String) {
        guard card.addedBy == userId else {
            print("❌ Unauthorized: User cannot edit this card")
            return
        }
        
        guard isValidCardText(newFront) else {
            print("❌ Invalid card front text")
            return
        }

        var updatedCard = card
        updatedCard.front = newFront.trimmingCharacters(in: .whitespacesAndNewlines)
        
        editVocabCard(card: updatedCard, userId: userId)
    }
    
    // MARK: - Edit Card Back
    func editVocabCardBack(card: VocabCardModel, newBack: String, userId: String) {
        guard card.addedBy == userId else {
            print("❌ Unauthorized: User cannot edit this card")
            return
        }

        guard isValidCardText(newBack) else {
            print("❌ Invalid card back text")
            return
        }

        var updatedCard = card
        updatedCard.back = newBack.trimmingCharacters(in: .whitespacesAndNewlines)
        
        editVocabCard(card: updatedCard, userId: userId)
    }
    
    // MARK: - Add Vocab Card
    func addVocabCard(to sheetId: String, front: String, back: String, addedBy: String) {
        guard isValidCardText(front), isValidCardText(back) else {
            print("❌ Invalid vocab card content")
            return
        }
        
        let newCard = VocabCardModel(
            id: UUID().uuidString,
            front: front.trimmingCharacters(in: .whitespacesAndNewlines),
            back: back.trimmingCharacters(in: .whitespacesAndNewlines),
            addedBy: addedBy,
            addedAt: Date(),
            favorited: false
        )
        
        vocabCardService.addVocabCard(to: sheetId, card: newCard)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Error adding vocab card: \(error.localizedDescription)")
                }
            }, receiveValue: {
                print("✅ Successfully added vocab card")
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Delete Vocab Card
    func deleteVocabCard(cardId: String, sheetId: String, userId: String) {
        guard let card = vocabCards.first(where: { $0.id == cardId }), card.addedBy == userId else {
            print("❌ Unauthorized: User cannot delete this card")
            return
        }

        vocabCardService.deleteVocabCard(cardId, from: sheetId)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Error deleting vocab card: \(error.localizedDescription)")
                }
            }, receiveValue: {
                print("✅ Successfully deleted vocab card")
            })
            .store(in: &cancellables)
    }

    // MARK: - Favorite Vocab Card
    func favoriteVocabCard(card: VocabCardModel) {
        var updatedCard = card
        updatedCard.favorited.toggle()

        vocabCardService.updateVocabCard(updatedCard)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Error favoriting vocab card: \(error.localizedDescription)")
                }
            }, receiveValue: {
                print("✅ Successfully updated favorite status")
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Validation Helpers
    private func isValidCardText(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 100
    }
    
    // Swipe to the next Vocab Card? Maybe within sheet
}
