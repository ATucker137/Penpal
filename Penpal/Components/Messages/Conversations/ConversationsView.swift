//
//  ConversationsView.swift
//  Penpal
//
//  Created by Austin William Tucker on 2/4/25.
//

import SwiftUI

// MARK: - ConversationView - Displays a list of all conversations
struct ConversationView: View {
    @ObservedObject var viewModel = ConversationViewModel()  // ViewModel to manage conversations
    @Binding var lastOpenedMessageId: String?  // Tracks the last opened conversation

    var body: some View {
        NavigationView {
            List(viewModel.conversations) { conversation in
                NavigationLink(destination: MessagesView(viewModel: MessagesViewModel(), conversationId: conversation.id)) {
                    HStack {
                        // MARK: - Profile Image (TODO: Fetch from database)
                        AsyncImage(url: URL(string: conversation.penpalProfileImage))
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())

                        VStack(alignment: .leading) {
                            // Display the penpal's name
                            Text(conversation.penpalName)
                                .font(.headline)
                            
                            // Display the last message, if available
                            if let lastMessage = conversation.lastMessage {
                                Text(lastMessage)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Conversations")
            .onAppear {
                // MARK: - Fetch Conversations (TODO: Implement in ViewModel)
                viewModel.fetchConversations()
            }
        }
    }
}

// MARK: - PreviewProvider - Provides a preview for SwiftUI canvas
struct ConversationView_Previews: PreviewProvider {
    static var previews: some View {
        ConversationView(lastOpenedMessageId: .constant(nil))
    }
}

// MARK: - TODO List
// TODO: Fetch actual penpal names from Firestore instead of IDs
// TODO: Implement profile images for penpals (fetch from Firestore storage)
// TODO: Implement `fetchConversations()` in `ConversationViewModel`
// TODO: Handle real-time updates to reflect new messages dynamically
