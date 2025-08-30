//
//  NotificationsService.swift
//  Penpal
//
//  Created by Austin William Tucker on 2/12/25.
//

import Foundation
import FirebaseFirestore
import UserNotifications


/*
 
 This will need to use the UserSessionManager which is going to be used as a singleton pattern across the entire app
 */
/// Service responsible for fetching and updating notifications in Firestore
class NotificationService {
    private let db = Firestore.firestore()
    private var userId: String? {
        return UserSession.shared.userId // dont think should be using shared
    }
    private let category = "Notifications Service"
    
    
    // MARK: - Fetches notifications for the current user
    func fetchNotifications(completion: @escaping (Result<[NotificationsModel], Error>) -> Void) {
        guard let userId = userId else {
            LoggerService.shared.log(.error, "User ID not available. Cannot fetch notifications.", category: category)
            completion(.success([]))
            return
        }

        LoggerService.shared.log(.info, "Fetching notifications for user: \(userId)...", category: category)

        db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    LoggerService.shared.log(.error, "Error fetching notifications: \(error.localizedDescription)", category: self.category)
                    completion(.failure(error))
                    return
                }

                guard let documents = snapshot?.documents else {
                    LoggerService.shared.log(.info, "No notification documents found for user: \(userId)", category: self.category)
                    completion(.success([]))
                    return
                }

                let notifications = documents.compactMap { doc in
                    try? doc.data(as: NotificationModel.self)
                }

                LoggerService.shared.log(.info, "Successfully fetched \(notifications.count) notifications for user: \(userId).", category: self.category)
                completion(.success(notifications))
            }
    }

    
    // MARK: - Marks a notification as read
    //  TODO: - Will Need To add This Within the Profile Settings
    func markNotificationAsRead(notificationId: String, completion: @escaping (Error?) -> Void) {
        LoggerService.shared.log(.info, "Marking notification \(notificationId) as read...", category: category)
        
        db.collection("notifications").document(notificationId).updateData(["isRead": true]) { error in
            if let error = error {
                LoggerService.shared.log(.error, "Failed to mark notification \(notificationId) as read: \(error.localizedDescription)", category: self.category)
            } else {
                LoggerService.shared.log(.info, "Successfully marked notification \(notificationId) as read.", category: self.category)
            }
            completion(error)
        }
    }

    
    // MARK: - Method to schedule notifications for meetings
    // Method to schedule notifications for meetings
    func scheduleMeetingNotifications(for meeting: Meeting, profileSettings: NotificationSettings) {
        LoggerService.shared.log(.info, "Preparing to schedule notifications for meeting: \(meeting.title) (\(meeting.id))", category: category)

        // Early return if meeting status is not "accepted"
        if meeting.status != "accepted" {
            LoggerService.shared.log(.info, "Meeting \(meeting.id) is not accepted. Skipping notification scheduling.", category: category)
            return
        }
        
        guard let meetingDate = dateFromString(meeting.datetime) else {
            LoggerService.shared.log(.error, "Invalid meeting date format for meeting: \(meeting.id)", category: category)
            return
        }

        // Schedule notifications based on user settings
        if profileSettings.notify24HoursBefore {
            LoggerService.shared.log(.info, "Scheduling 24h notification for meeting \(meeting.id)", category: category)
            scheduleNotification(for: meeting, at: meetingDate.addingTimeInterval(-24*60*60)) // 24 hours before
        }
        if profileSettings.notify6HoursBefore {
            LoggerService.shared.log(.info, "Scheduling 6h notification for meeting \(meeting.id)", category: category)
            scheduleNotification(for: meeting, at: meetingDate.addingTimeInterval(-6*60*60)) // 6 hours before
        }
        if profileSettings.notify1HourBefore {
            LoggerService.shared.log(.info, "Scheduling 1h notification for meeting \(meeting.id)", category: category)
            scheduleNotification(for: meeting, at: meetingDate.addingTimeInterval(-60*60)) // 1 hour before
        }
    }

    
    // MARK: - Schedules a notification for the user based on the meeting and time
    func scheduleNotification(for meeting: Meeting, at time: Date, idSuffix: String = "") {
        let content = UNMutableNotificationContent()
        content.title = "Reminder: \(meeting.title)"
        content.body = "Your meeting is coming up soon! Please be ready to join."
        content.sound = .default
        
        let interval = time.timeIntervalSinceNow
        guard interval > 0 else {
            LoggerService.shared.log(.error, "Attempted to schedule notification in the past for meeting \(meeting.id)", category: category)
            return
        }

        // Trigger for the notification based on the provided time
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)

        // Use the idSuffix parameter directly — do NOT redeclare it here
        let request = UNNotificationRequest(identifier: "\(meeting.id)\(idSuffix)", content: content, trigger: trigger)
        
        // Add the request to the notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                LoggerService.shared.log(.error, "Error scheduling notification for meeting \(meeting.id): \(error.localizedDescription)", category: category)
            } else {
                LoggerService.shared.log(.info, "Notification successfully scheduled for meeting \(meeting.id) at \(time)", category: category)
            }
        }
    }



    
    // MARK: - Helper function to convert string to date (implement this function)
    private func dateFromString(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss" // Example format, adjust if needed

        if let date = formatter.date(from: dateString) {
            LoggerService.shared.log(.info, "Successfully parsed date string: \(dateString)", category: category)
            return date
        } else {
            LoggerService.shared.log(.error, "Failed to parse date from string: \(dateString)", category: category)
            return nil
        }
    }
    
    
    // MARK: - Cancels all scheduled notifications for a given meeting ID
    func cancelScheduledNotifications(for meetingId: String) {
        let identifiers = [
            "\(meetingId)_24h",
            "\(meetingId)_6h",
            "\(meetingId)_1h"
        ]
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        LoggerService.shared.log(.info, "Cancelled notifications for meeting \(meetingId): \(identifiers)", category: category)
    }

    // MARK: - Reschedules notifications for a meeting by first cancelling existing ones, then scheduling new ones
    func rescheduleMeetingNotifications(for meeting: Meeting, profileSettings: NotificationSettings) {
        LoggerService.shared.log(.info, "Rescheduling notifications for meeting: \(meeting.title) (\(meeting.id))", category: category)

        // Cancel any existing notifications for this meeting
        cancelScheduledNotifications(for: meeting.id)

        // Only schedule if meeting is accepted
        guard meeting.status == "accepted" else {
            LoggerService.shared.log(.info, "Meeting \(meeting.id) is not accepted. Skipping notification scheduling.", category: category)
            return
        }
        
        guard let meetingDate = dateFromString(meeting.datetime) else {
            LoggerService.shared.log(.error, "Invalid meeting date format for meeting: \(meeting.id)", category: category)
            return
        }

        // Schedule notifications based on user preferences
        if profileSettings.notify24HoursBefore {
            LoggerService.shared.log(.info, "Scheduling 24h notification for meeting \(meeting.id)", category: category)
            scheduleNotification(for: meeting, at: meetingDate.addingTimeInterval(-24*60*60), idSuffix: "_24h")
        }
        if profileSettings.notify6HoursBefore {
            LoggerService.shared.log(.info, "Scheduling 6h notification for meeting \(meeting.id)", category: category)
            scheduleNotification(for: meeting, at: meetingDate.addingTimeInterval(-6*60*60), idSuffix: "_6h")
        }
        if profileSettings.notify1HourBefore {
            LoggerService.shared.log(.info, "Scheduling 1h notification for meeting \(meeting.id)", category: category)
            scheduleNotification(for: meeting, at: meetingDate.addingTimeInterval(-60*60), idSuffix: "_1h")
        }
    }
}
