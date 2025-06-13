//
//  MessagesView.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//

import SwiftUI
import FirebaseAuth


// MARK: - MessageView - The main view for displaying messages in a conversation
struct MessagesView: View {
    @ObservedObject var viewModel: MessagesViewModel // MessagesViewModel will handle everything in the background
    let conversationId: String // --- TODO: - Should this be brought in another way?
    @State private var messageText = "" // State for the input text field
    @State private var scrollToBottom = UUID() // Helps auto-scroll

    var body: some View {
        // The main vertical stack that holds the entire conversation messages
        VStack {
            // ScrollViewReader is used for programmatic scrolling
            ScrollViewReader { proxy in
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
                .onChange(of: viewModel.messages.count) { _ in
                    scrollToBottom(proxy: proxy)
                }
                .onAppear {
                    scrollToBottom(proxy: proxy) // Ensures messages auto-scroll on first load
                }
            }

            // Message input field
            HStack {
                TextField("Type a message...", text: $messageText)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .frame(height: 40)
                    .submitLabel(.send) // Pressing "return" sends the message
                    .onSubmit { sendMessage() } // Calls sendMessage when return is pressed
                
                Button(action: {
                    sendMessage()
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(messageText.isEmpty ? .gray : .blue)
                        .padding()
                }
                .disabled(messageText.isEmpty)
            }
            .padding()
        }
    }
    // This modifier runs when the view appears, ensuring messages are fetched for the current conversation
    .onAppear {
        viewModel.fetchMessages(for: conversationId)
    }
    
    // Scrolls to the bottom of the conversation
    private func scrollToBottom(proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation {
                if let lastMessage = viewModel.messages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
        }
    }
    
    // Handles sending a message
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        viewModel.sendMessage(text: messageText, conversationId: conversationId)
        messageText = "" // Clear input field after sending
    }
}


    

// A view representing a single message bubble in the conversation.
// TODO: - THIS NEEDS TO BE LOOKED INTO MORE
// MARK: - MessageBubble - A view representing a single chat message
struct MessageBubble: View {
    let message: MessagesModel // The message data to be displayed

    var body: some View {
        let currentUserId = Auth.auth().currentUser?.uid ?? "" // Get the current user's ID

        HStack {
            if message.senderId == currentUserId {
                // MARK: - Right Side (User's Messages)
                Spacer() // Pushes user's message to the right
                Text(message.text)
                    .padding()
                    .background(Color(red: 1.0, green: 0.4, blue: 0.4)) // Deep Coral Pink (#FF6666)
                    .foregroundColor(.white) // White text for contrast
                    .clipShape(RoundedRectangle(cornerRadius: 12)) // Rounded bubble
                    .frame(maxWidth: 250, alignment: .trailing) // Limit width and align right
            } else {
                // MARK: - Left Side (Penpal's Messages)
                Text(message.text)
                    .padding()
                    .background(Color(red: 1.0, green: 0.8, blue: 0.8)) // Soft Coral Pink (#FFCCCC)
                    .foregroundColor(.black) // Black text for readability
                    .clipShape(RoundedRectangle(cornerRadius: 12)) // Rounded bubble
                    .frame(maxWidth: 250, alignment: .leading) // Limit width and align left
                Spacer() // Pushes penpal’s message to the left
            }
        }
        .padding(.horizontal) // Horizontal padding for spacing
    }
}

// MARK: - Preview for MessageBubble
struct MessageBubble_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 10) {
            // Example of a message from the current user
            MessageBubble(message: MessagesModel(
                id: "1",
                senderId: "currentUserId",
                text: "Hola! ¿Cómo estás?",
                sentAt: Date().timeIntervalSince1970
            ))
            
            // Example of a message from the penpal
            MessageBubble(message: MessagesModel(
                id: "2",
                senderId: "penpalUserId",
                text: "¡Hola! Estoy bien, gracias. ¿Y tú?",
                sentAt: Date().timeIntervalSince1970
            ))
        }
        .padding()
        .previewLayout(.sizeThatFits) // Adjusts preview to fit content size
        .background(Color.white) // White background to simulate chat screen
    }
}

