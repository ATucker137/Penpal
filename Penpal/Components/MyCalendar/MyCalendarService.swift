//
//  MyCalendarService.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

protocol CalendarServiceProtocol {
    func fetchEvents(for userId: String, date: Date, completion: @escaping (Result<[CalendarEvent], Error>) -> Void)
}


// This all needs to be looked over
class MyCalendarService: CalendarServiceProtocol {
    private let db = Firestore.firestore()
    private let category = "Calendar Service"

    
    // NOTE: Much of this might not be needed because its basically a bunch of Meetings
    
    func fetchMyCalendar(for userId: String, completion: @escaping (Result<MyCalendar, Error>) -> Void) {
        db.collection("calendars").document(userId).getDocument { document, error in
            if let error = error {
                LoggerService.shared.log(.error, "Failed to fetch calendar for user \(userId): \(error.localizedDescription)", category: self.category )
                completion(.failure(error))
                return
            }
            guard let document = document else {
                LoggerService.shared.log(.error, "No document returned for user \(userId).", category: self.category)
                completion(.failure(NSError(domain: "FirestoreError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No document found."])))
                return
            }

            if !document.exists {
                LoggerService.shared.log(.error, "Calendar document does not exist for user \(userId).", category: self.category)
                completion(.failure(NSError(domain: "NotFoundError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Calendar not found."])))
                return
            }

            guard let data = document.data(), let calendar = MyCalendar.fromFireStoreData(data) else {
                LoggerService.shared.log(.error, "Failed to decode calendar data for user \(userId).", category: self.category)
                completion(.failure(NSError(domain: "DataError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to decode calendar data."])))
                return
            }

            LoggerService.shared.log(.info, "Successfully fetched calendar for user \(userId).", category: self.category)
            completion(.success(calendar))
        }
    }

    
    // MARK: - Save Event Through Firestore
    func saveMyCalendar(_ calendar: MyCalendar, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try db.collection(collectionPath).document(calendar.id).setData(from: calendar)
            LoggerService.shared.log(.info, "Successfully saved calendar for user \(calendar.id).", category: self.category)
            completion(.success(()))
        } catch {
            LoggerService.shared.log(.error, "Failed to save calendar for user \(calendar.id): \(error.localizedDescription)", category: self.category)
            completion(.failure(error))
        }
    }

    func fetchEvents(for userId: String, date: Date, completion: @escaping (Result<[MeetingModel], Error>) -> Void) {
        meetingService.fetchAllMeetings { result in
            switch result {
            case .success(let meetings):
                let startOfDay = Calendar.current.startOfDay(for: date)
                let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

                let filtered = meetings.filter {
                    $0.participants.contains(userId) &&
                    $0.startTime >= startOfDay &&
                    $0.startTime < endOfDay
                }
                LoggerService.shared.log(.info, "Fetched \(filtered.count) events for user \(userId) on \(date).", category: self.category)
                completion(.success(filtered))

            case .failure(let error):
                LoggerService.shared.log(.error, "Failed to fetch events for user \(userId) on \(date): \(error.localizedDescription)", category: self.category)
                completion(.failure(error))
            }
        }
    }


    
    // MARK: - Update Calendar Through Firestore
    func updateMyCalendar(for userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        LoggerService.shared.log(.info, "Attempting to update calendar for user \(userId).", category: self.category)
        fetchMyCalendar(for: userId) { result in
            switch result {
            case .success(let calendar):
                // Store the updated calendar locally, maybe in your ViewModel
                // e.g., self.myCalendar = calendar
                LoggerService.shared.log(.info, "Successfully updated calendar for user \(userId).", category: self.category)
                completion(.success(()))
            case .failure(let error):
                LoggerService.shared.log(.error, "Failed to update calendar for user \(userId): \(error.localizedDescription)", category: self.category)
                completion(.failure(error))
            }
        }
    }

    
    
    
    // MARK: - Add Calendar Through Firestore
    // Needs To Make Sure This Isnt A time thats already there
    
    
    // MARK: - 

    
    
}
