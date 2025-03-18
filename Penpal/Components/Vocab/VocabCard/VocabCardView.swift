//
//  VocabCardView.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//



import SwiftUI


struct VocabcardView: View {
    @StateObject private var viewModel = VocabCardViewModel() // Intiialize the viewmodel
    let userId: String // PAss in the userId to fetch the profile
    @Binding var selectedTab: Tab // Within Main Tab View can navigate to hear
    
    
    
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
                        viewModel.fetchUserProfile(userId: userId)
                    }) {
                        Text("Retry")
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            
            // MARK: - Needs List of All the Vocab Sheet A User Has
            
            
        }
    }
}

struct VocabSheetView_Previews: PreviewProvider {
    static var previews: some View {
        VocabSheetView(userId: "sampleUserId")
    }
}
