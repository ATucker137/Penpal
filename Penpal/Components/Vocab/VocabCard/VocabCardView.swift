//
//  VocabCardView.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//

import SwiftUI

struct VocabCardView: View {
    @StateObject private var viewModel = VocabCardViewModel() // Initialize the viewmodel
    let userId: String // Pass in the userId to fetch the profile
    @Binding var selectedTab: Tab // Within Main Tab View can navigate to here
    @State private var isNavigatingToReview = false // To track navigation state
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                // Show a loading indicator
                ProgressView("Loading Vocab Card...")
                    .padding()
            } else if let errorMessage = viewModel.errorMessage {
                // Show an error message
                VStack {
                    Text("Error")
                        .font(.headline)
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button(action: {
                        viewModel.fetchVocabCards() // Trigger fetching of vocab cards
                    }) {
                        Text("Retry")
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
                .padding()
            } else {
                // Display the list of vocab cards for the user
                List(viewModel.vocabCards) { card in
                    VStack(alignment: .leading) {
                        Text(card.front) // Display the front of the card
                            .font(.headline)
                            .padding(.bottom, 5)
                        Text(card.back) // Display the back of the card (optional preview)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                }

                // Review Button
                Button(action: {
                    isNavigatingToReview.toggle() // Navigate to VocabCardReviewView
                }) {
                    Text("Review")
                        .font(.title2)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.top, 20)
                }
                .padding(.bottom, 20)

                // Navigation Link to VocabCardReviewView
                NavigationLink(destination: VocabCardReviewView(vocabSheetId: "sampleSheetId", userId: userId, vocabCardService: VocabCardService()), isActive: $isNavigatingToReview) {
                    EmptyView() // This view is hidden, it's only for triggering the navigation
                }
            }
        }
        .onAppear {
            viewModel.fetchVocabCards() // Fetch the vocab cards when the view appears
        }
        .navigationTitle("Vocab Cards")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct VocabCardView_Previews: PreviewProvider {
    static var previews: some View {
        VocabCardView(userId: "sampleUserId", selectedTab: .constant(.vocab))
    }
}
