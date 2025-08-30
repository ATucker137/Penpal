//
//  NotificationsView.swift
//  Penpal
//
//  Created by Austin William Tucker on 2/12/25.
//

import SwiftUI
import FirebaseFirestore

struct NotificationsView: View {
    @ObservedObject var viewModel: NotificationsViewModel // ViewModel to manage notifications

    var body: some View {
        NavigationView {
            List(viewModel.notifications) { notification in
                NotificationRow(notification: notification)
            }
            .navigationTitle("Notifications")
            .onAppear {
                viewModel.fetchNotifications() // Fetch notifications on appear
            }
        }
    }
}

struct NotificationRow: View {
    let notification: NotificationsModel

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(notification.title)
                    .font(.headline)
                Text(notification.body)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            if !notification.isRead {
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
            }
        }
        .padding()
    }
}
