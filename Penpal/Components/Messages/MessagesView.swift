//
//  MessagesView.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//

import SwiftUI
import FirebaseAuth


// MARK: - MessageView - the main view for displaying messages in a conversation
struct MessagesView: View {
    @ObservedObject var viewModel: MessagesViewModel //MessagesViewModel will handle verything in the background
    let conversationId: String // --- TODO: -  Should this be brough in another way?
    @State private var messageText = "" // State for the input text field
    @State private var scrollToBottom = UUID() // Helps auto-scroll

    var body: some View {
        // The main vertical stack that hold the entire conversation messages
        VStack {
            // ScrollViewReader is used for programtic scrolling
            ScrollViewReader { scrollView in
                // ScrollView allows the user to scroll through messages
                ScrollView {
                    // LazyVStack is a vertical stack that lazily loads views as they come into view
                    LazyVStack(alignment: .leading, spacing: 10) {
                        // Loop through each message in the viewModel's messages array, sorted by sent time
                        ForEach(viewModel.messages.sorted(by: { $0.sentAt < $1.sentAt }), id: \.id) { message in
                            // Each message is displayed using the MessageBubble view
                            MessageBubble(message: message)
                                .id(message.id) // Each message has a unique ID to help with scrolling to the latest message
                        }
                    }
                        }
                    }
                }
                // Triggered whenever the count of messages changes (e.g., new message is added)
                .onChange(of: viewModel.messages.count) { _ in
                    // If there are new messages, scroll to the last one automatically
                    if let lastMessage = viewModel.messages.last {
                        DispatchQueue.main.async {
                            withAnimation {
                                // Scroll to the bottom to show the latest message
                                scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                // Message input field
                HStack {
                    TextField("Type a message...", text: $messageText)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .frame(height: 40)
                    
                    Button(action: {
                        sendMessage()
                    }) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.blue)
                            .padding()
                    }
                }
                .padding()
            }
            }
        }
        // This modifier runs when the view appears, ensuring messages are fetched for the current conversation
        .onAppear {
            viewModel.fetchMessages(for: conversationId)
        }
    }
}

// A view representing a single message bubble in the conversation.
// TODO: - THIS NEEDS TO BE LOOKED INTO MORE
struct MessageBubble: View {
    let message: MessagesModel // The message data that will be displayed

    var body: some View {
        let currentUserId = Auth.auth().currentUser?.uid ?? ""

        HStack {
            if message.senderId == currentUserId {
                Spacer() // Pushes user message to the right
                Text(message.text)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(maxWidth: 250, alignment: .trailing)
            } else {
                Text(message.text)
                    .padding()
                    .background(Color.gray.opacity(0.3))
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(maxWidth: 250, alignment: .leading)
                Spacer() // Pushes penpal’s message to the left
            }
        }
        .padding(.horizontal)
    }
}
