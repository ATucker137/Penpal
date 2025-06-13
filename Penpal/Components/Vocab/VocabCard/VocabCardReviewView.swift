//
//  VocabCardReviewView.swift
//  Penpal
//
//  Created by Austin William Tucker on 3/18/25.
//
import SwiftUI

struct VocabCardReviewView: View {
    let vocabSheetId: String
    let userId: String
    @StateObject private var viewModel: VocabCardsViewModel
    @State private var currentCardIndex: Int = 0
    @State private var flipped = false

    init(vocabSheetId: String, userId: String, vocabCardService: VocabCardService) {
        self.vocabSheetId = vocabSheetId
        self.userId = userId
        self._viewModel = StateObject(wrappedValue: VocabCardsViewModel(vocabSheetId: vocabSheetId, vocabCardService: vocabCardService))
    }

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading Cards...")
                    .padding()
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
                Button("Retry") {
                    viewModel.fetchVocabCards()
                }
            } else if let card = viewModel.vocabCards[safe: currentCardIndex] {
                VStack {
                    // Card View with Swipe Gesture for navigation
                    ZStack {
                        // Front of the card
                        VStack {
                            Text(card.front)
                                .font(.largeTitle)
                                .padding()
                        }
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .rotation3DEffect(
                            .degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0)
                        )
                        .onTapGesture {
                            withAnimation(.spring()) {
                                flipped.toggle() // Flip the card
                            }
                        }
                        .padding()

                        // Back of the card (will show only when flipped)
                        VStack {
                            Text(card.back)
                                .font(.title)
                                .foregroundColor(.gray)
                        }
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .rotation3DEffect(
                            .degrees(flipped ? 0 : 180), axis: (x: 0, y: 1, z: 0)
                        )
                        .opacity(flipped ? 1 : 0) // Show when flipped
                        .padding()
                    }

                    // Star Button to Favorite
                    Button(action: {
                        toggleFavorite(cardId: card.id)
                    }) {
                        Image(systemName: "star.fill")
                            .foregroundColor(card.isFavorite ? .yellow : .gray)
                            .font(.title)
                            .padding()
                    }

                    // Navigation Buttons (Previous and Next)
                    HStack {
                        Button("Previous") {
                            prevCard()
                        }
                        .padding()
                        Button("Next") {
                            nextCard()
                        }
                        .padding()
                    }
                }
            } else {
                Text("No cards available.")
            }
        }
        .onAppear {
            viewModel.fetchVocabCards()
        }
        .navigationTitle("Review Cards")
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 100 {
                        nextCard() // Swipe right for next card
                    } else if value.translation.width < -100 {
                        prevCard() // Swipe left for previous card
                    }
                }
        )
    }

    private func nextCard() {
        if currentCardIndex < viewModel.vocabCards.count - 1 {
            currentCardIndex += 1
            flipped = false // Reset flip animation when switching cards
        }
    }

    private func prevCard() {
        if currentCardIndex > 0 {
            currentCardIndex -= 1
            flipped = false // Reset flip animation when switching cards
        }
    }

    private func toggleFavorite(cardId: String) {
        // Implement the logic to mark the card as favorite in your view model or data source
        viewModel.toggleFavorite(for: cardId)
    }
}

struct VocabCardReviewView_Previews: PreviewProvider {
    static var previews: some View {
        VocabCardReviewView(vocabSheetId: "sampleSheetId", userId: "sampleUserId", vocabCardService: VocabCardService())
    }
}
