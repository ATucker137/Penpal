//
//  NotificationsViewModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 2/12/25.
//

import Foundation
import Combine

class NotificationsViewModel: ObservableObject {
    // MARK: - Properties

    @Published var notifications: [NotificationsModel] = []

    private let notificationService = NotificationService()
    private let logCategory = "Notifications ViewModel"
    private let sqliteManager = SQLiteManager.shared


    // MARK: - Fetch Notifications
    func fetchNotifications() {
        LoggerService.shared.log(.info, "Fetching notifications...", category: logCategory)

        notificationService.fetchNotifications { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let notifications):
                    // Mark all fetched notifications as synced
                    let syncedNotifications = notifications.map { notif -> NotificationsModel in
                        var copy = notif
                        copy.isSynced = true
                        return copy
                    }

                    self?.notifications = syncedNotifications
                    self?.sqliteManager.saveNotificationsToSQLite(syncedNotifications) // Store locally with sync flag
                    LoggerService.shared.log(.info, "✅ Successfully fetched and saved \(syncedNotifications.count) notifications.", category: self?.logCategory ?? "Unknown")

                case .failure(let error):
                    LoggerService.shared.log(.error, "❌ Failed to fetch notifications: \(error.localizedDescription)", category: self?.logCategory ?? "Unknown")
                }
            }
        }
    }


    // MARK: - Mark Notification as Read
    func markAsRead(notificationId: String) {
        LoggerService.shared.log(.info, "Marking notification \(notificationId) as read...", category: logCategory)

        notificationService.markNotificationAsRead(notificationId: notificationId) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    LoggerService.shared.log(.error, "❌ Failed to mark notification as read: \(error.localizedDescription)", category: self?.logCategory ?? "Unknown")
                    return
                }
                if let index = self?.notifications.firstIndex(where: { $0.id == notificationId }) {
                    self?.notifications[index].isRead = true
                    self?.sqliteManager.updateReadStatusInSQLite(notificationId: notificationId) // ✅ Update local
                    LoggerService.shared.log(.info, "✅ Notification \(notificationId) marked as read (both local and server).", category: self?.logCategory ?? "Unknown")
                }
            }
        }
    }
    
    // MARK: - Mark Schedule Meeting as Read
    func scheduleMeetingReminders(for meeting: Meeting, with settings: UserProfileSettings) {
            LoggerService.shared.log(.info, "Scheduling reminders for meeting: \(meeting.title)", category: logCategory)
            notificationService.scheduleMeetingNotifications(for: meeting, profileSettings: settings)
    }
    
    // MARK: - Load Notifications from Local SQLite Cache
    func loadCachedNotifications() {
        LoggerService.shared.log(.info, "Loading notifications from local cache...", category: logCategory)
        let cached = sqliteManager.loadNotificationsFromSQLite()
        DispatchQueue.main.async {
            self.notifications = cached
            LoggerService.shared.log(.info, "✅ Loaded \(cached.count) notifications from SQLite.", category: self.logCategory)
        }
    }
    
    // MARK: - Delete Notification (locally)
    func deleteNotification(notificationId: String) {
        LoggerService.shared.log(.info, "Deleting notification \(notificationId)...", category: logCategory)
        sqliteManager.deleteNotificationFromSQLite(id: notificationId)
        notifications.removeAll { $0.id == notificationId }
        LoggerService.shared.log(.info, "✅ Deleted notification \(notificationId) from SQLite and in-memory list.", category: logCategory)
    }

    // MARK: - Delete Expired Notifications (locally)
    func deleteExpiredNotifications() {
        LoggerService.shared.log(.info, "Deleting expired notifications...", category: logCategory)
        sqliteManager.deleteExpiredNotifications()
        let before = notifications.count
        notifications.removeAll { $0.expirationDate < Date() }
        LoggerService.shared.log(.info, "✅ Removed \(before - notifications.count) expired notifications from SQLite and memory.", category: logCategory)
    }
    
    //MARK: - Cancel scheduled notifications for a meeting
    func cancelScheduledNotifications(for meetingId: String) {
        LoggerService.shared.log(.info, "Canceling scheduled notifications for meeting \(meetingId)...", category: logCategory)
        notificationService.cancelScheduledNotifications(for: meetingId)
    }

    //MARK: - Reschedule notifications for a meeting
    func rescheduleMeetingNotifications(for meeting: Meeting, with settings: NotificationSettings) {
        LoggerService.shared.log(.info, "Rescheduling notifications for meeting \(meeting.title)...", category: logCategory)
        notificationService.rescheduleMeetingNotifications(for: meeting, profileSettings: settings)
    }
}
