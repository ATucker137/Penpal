//
//  MyCalendarService.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//
//  The service layer handles Firestore integration. Fetches and saves calendarEvents.

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

protocol CalendarServiceProtocol {
    func fetchEvents(for userId: String, date: Date, completion: @escaping (Result<[CalendarEvent], Error>) -> Void)
}

class MyCalendarService: CalendarServiceProtocol {
    private let db = Firestore.firestore()
    
    // NOTE: Much of this might not be needed because its basically a bunch of Meetings
    
    
    // MARK: - Fetch Events Through Firestore
    func fetchMyCalendar(for userId: String, date: Date, completion: @escaping (Result<[MyCalendar], Error>) -> Void) {
        
        // Ensure user ID is valid
        guard !userId.isEmpty else {
            completion(.failure(NSError(domain: "UserIDError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID."])))
            return
        }
        // Calculate time range
        let startOfDay = Calendar.current.startOfDay(for: date)
        guard let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) else {
            completion(.failure(NSError(domain: "DateError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to calculate end of day."])))
            return
        }
        
        db.collection("profiles").document(userId).collection("calendarEvents")
            .whereField("startTime", isGreaterThanOrEqualTo: startOfDay)
            .whereField("startTime", isLessThan: endOfDay)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    do {
                        let events = try snapshot?.documents.compactMap {
                            try $0.data(as: MyCalendar.self)
                        } ?? []
                        completion(.success(events))
                    } catch {
                        completion(.failure(error))
                    }
                }
            }
    }
    
    // MARK: - Save Event Through Firestore
    func saveMyCalendar(_ calendar: MyCalendar, completion: @escaping (Result<Void, Error>) -> Void) {
            do {
                try db.collection(collectionPath).document(calendar.id).setData(from: event)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
    }
    
    // MARK: - Delete Event Through Firestore
    // Note there Shouldnt be any Deletion of MyCalendar
    func delete(_ id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection(collectionPath).document(id).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Update Evnt Through Firestore

}
