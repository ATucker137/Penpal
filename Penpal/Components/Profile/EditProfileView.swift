//
//  EditProfileView.swift
//  Penpal
//
//  Created by Austin William Tucker on 2/14/25.
//

import SwiftUI
import FirebaseFirestore

struct EditProfileView: View {
    @Binding var profile: Profile

    @State private var notificationSettings = NotificationSettings()
    @State private var isLoadingSettings = true

    var body: some View {
        Form {
            if isLoadingSettings {
                ProgressView("Loading Notification Settings...")
            } else {
                Section(header: Text("Notification Preferences")) {
                    Toggle("1 Hour Before", isOn: $notificationSettings.notify1HourBefore)
                        .toggleStyle(PinkToggleStyle())
                        .onChange(of: notificationSettings.notify1HourBefore) { _ in saveNotificationSettings() }

                    Toggle("6 Hours Before", isOn: $notificationSettings.notify6HoursBefore)
                        .toggleStyle(PinkToggleStyle())
                        .onChange(of: notificationSettings.notify6HoursBefore) { _ in saveNotificationSettings() }

                    Toggle("24 Hours Before", isOn: $notificationSettings.notify24HoursBefore)
                        .toggleStyle(PinkToggleStyle())
                        .onChange(of: notificationSettings.notify24HoursBefore) { _ in saveNotificationSettings() }
                }
                .padding(.vertical, 10)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadNotificationSettings() }
    }

    private func loadNotificationSettings() {
        guard let userId = UserSession.shared.userId else { return }

        Firestore.firestore().collection("users").document(userId).getDocument { snapshot, error in
            defer { isLoadingSettings = false }

            guard let data = snapshot?.data(),
                  let settingsData = data["notificationSettings"] as? [String: Any],
                  let settings = NotificationSettings.fromFireStoreData(settingsData) else {
                print("Failed to load settings or using default.")
                return
            }

            notificationSettings = settings
        }
    }

    private func saveNotificationSettings() {
        guard let userId = UserSession.shared.userId else { return }

        let data = notificationSettings.toFireStoreData()

        Firestore.firestore().collection("users").document(userId).updateData([
            "notificationSettings": data
        ]) { error in
            if let error = error {
                print("Error saving notification settings: \(error)")
            } else {
                print("Notification settings saved.")
            }
        }
    }
}

struct PinkToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(configuration.isOn ? Color.pink : Color.gray.opacity(0.3))
                    .frame(width: 50, height: 30)

                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .offset(x: configuration.isOn ? 10 : -10)
                    .animation(.easeInOut, value: configuration.isOn)
            }
            .onTapGesture {
                configuration.isOn.toggle()
            }
        }
    }
}

struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView(profile: .constant(Profile(
            firstName: "Austin",
            lastName: "Tucker",
            email: "austin@example.com",
            hobbies: [],
            goals: []
        )))
    }
}
