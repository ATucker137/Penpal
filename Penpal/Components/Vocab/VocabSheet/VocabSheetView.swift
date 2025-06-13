//
//  VocabSheetView.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//
import SwiftUI

struct VocabSheetView: View {
    @StateObject private var viewModel: VocabSheetViewModel
    let userId: String
    @Binding var selectedTab: Tab

    init(userId: String, selectedTab: Binding<Tab>, vocabSheetService: VocabSheetService) {
        self.userId = userId
        self._selectedTab = selectedTab
        self._viewModel = StateObject(wrappedValue: VocabSheetViewModel(vocabSheetService: vocabSheetService))
    }

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading Vocab Sheets...")
                    .padding()
            } else if let errorMessage = viewModel.errorMessage {
                VStack {
                    Text("Error")
                        .font(.headline)
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button(action: {
                        viewModel.fetchVocabSheets()
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
                // List of User's Vocab Sheets
                List(viewModel.vocabSheets) { sheet in
                    NavigationLink(destination: VocabCardsView(
                        vocabSheetId: sheet.id,
                        userId: userId,
                        vocabCardService: VocabCardService())) {
                        VStack(alignment: .leading) {
                            Text(sheet.name)
                                .font(.headline)
                            Text("Total Cards: \(sheet.totalCards)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .onAppear {
            viewModel.fetchVocabSheets()
        }
        .navigationTitle("My Vocab Sheets")
        .toolbar {
            Button(action: {
                viewModel.addVocabSheet(name: "New Sheet", createdBy: userId)
            }) {
                Image(systemName: "plus")
            }
        }
    }
}

struct VocabSheetView_Previews: PreviewProvider {
    static var previews: some View {
        VocabSheetView(
            userId: "sampleUserId",
            selectedTab: .constant(.vocab),
            vocabSheetService: VocabSheetService()
        )
    }
}
