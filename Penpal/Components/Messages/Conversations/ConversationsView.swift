//
//  ConversationsView.swift
//  Penpal
//
//  Created by Austin William Tucker on 2/4/25.
//

import SwiftUI

struct ConversationView: View {
    @ObservedObject var viewModel = ConversationViewModel()  // ViewModel that holds the list of conversations
    @Binding var lastOpenedMessageId: String?  // Binding to save the selected conversation ID

    var body: some View {
        NavigationView {
            List(viewModel.conversations) { conversation in
                Button(action: {
                    // Save the selected conversation ID in UserDefaults
                    lastOpenedMessageId = conversation.id
                    UserDefaults.standard.set(conversation.id, forKey: "lastOpenedMessageId")
                }) {
                    VStack(alignment: .leading) {
                        Text("Conversation with \(conversation.penpalId)")  // Display penpal name or ID (you can fetch more details if needed)
                            .font(.headline)
                        if let lastMessage = conversation.lastMessage {
                            Text(lastMessage)  // Display the last message
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Conversations")
        }
    }
}
