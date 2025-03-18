//
//  NotificationsService.swift
//  Penpal
//
//  Created by Austin William Tucker on 2/12/25.
//

import Foundation
import FirebaseFirestore


/*
 
 This will need to use the UserSessionManager which is going to be used as a singleton pattern across the entire app
 */
/// Service responsible for fetching and updating notifications in Firestore
class NotificationService {
    private let db = Firestore.firestore()
    private var userId: String? {
        return UserSession.shared.userId
    }
    
    /// Fetches notifications for the current user
    func fetchNotifications(completion: @escaping (Result<[NotificationModel], Error>) -> Void) {
        db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([])) // Return an empty array if no notifications
                    return
                }
                
                let notifications = documents.compactMap { doc in
                    try? doc.data(as: NotificationModel.self)
                }
                completion(.success(notifications))
            }
    }
    
    /// Marks a notification as read
    //  TODO: - Will Need To add This Within the Profile Settings
    func markNotificationAsRead(notificationId: String, completion: @escaping (Error?) -> Void) {
        db.collection("notifications").document(notificationId).updateData(["isRead": true]) { error in
            completion(error)
        }
    }
    
    // Method to schedule notifications for meetings
    func scheduleMeetingNotifications(for meeting: Meeting, profileSettings: UserProfileSettings) {
        // Early return if meeting status is not "accepted"
        if meeting.status != "accepted" {
            return
        }
        
        guard let meetingDate = dateFromString(meeting.datetime) else {
            return
        }

        // Schedule notifications based on user settings
        if profileSettings.notify24h {
            scheduleNotification(for: meeting, at: meetingDate.addingTimeInterval(-24*60*60)) // 24 hours before
        }
        if profileSettings.notify6h {
            scheduleNotification(for: meeting, at: meetingDate.addingTimeInterval(-6*60*60)) // 6 hours before
        }
        if profileSettings.notify1h {
            scheduleNotification(for: meeting, at: meetingDate.addingTimeInterval(-60*60)) // 1 hour before
        }
    }
    
    /// Schedules a notification for the user based on the meeting and time
    func scheduleNotification(for meeting: Meeting, at time: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Reminder: \(meeting.title)"
        content.body = "Your meeting is coming up soon! Please be ready to join."
        content.sound = .default
        
        // Create a trigger for the notification based on the provided time
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: time.timeIntervalSinceNow, repeats: false)
        
        // Create a request for the notification
        let request = UNNotificationRequest(identifier: meeting.id, content: content, trigger: trigger)
        
        // Add the request to the notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Notification scheduled for meeting: \(meeting.title)")
            }
        }
    }
    
    // Helper function to convert string to date (implement this function)
    private func dateFromString(_ dateString: String) -> Date? {
        // Implement the logic for parsing a date string into a Date object
        // For example, using DateFormatter:
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss" // Example format, adjust as needed
        return formatter.date(from: dateString)
    }
    

}
