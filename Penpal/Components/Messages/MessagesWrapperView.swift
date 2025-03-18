//
//  MessagesWrapperView.swift
//  Penpal
//
//  Created by Austin William Tucker on 3/3/25.
//

import SwiftUI

struct MessagesWrapperView: View {
    @Binding var selectedTab: Tab
    @State private var lastOpenedMessageId: String? = UserDefaults.standard.string(forKey: "lastOpenedMessageId")

    var body: some View {
        if let messageId = lastOpenedMessageId {
            MessagesView(
                messageId: messageId,
                lastOpenedMessageId: $lastOpenedMessageId
            )
        } else {
            ConversationView(
                lastOpenedMessageId: $lastOpenedMessageId
            )
        }
    }
}
