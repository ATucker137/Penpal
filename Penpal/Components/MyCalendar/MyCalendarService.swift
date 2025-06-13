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
    
    // NOTE: Much of this might not be needed because its basically a bunch of Meetings
    
    func fetchMyCalendar(for userId: String, completion: @escaping (Result<MyCalendar, Error>) -> Void) {
        db.collection("calendars").document(userId).getDocument { document, error in
            if let error = error {
                completion(.failure(error))
            } else if let document = document, document.exists {
                if let data = document.data(),
                   let calendar = MyCalendar.fromFireStoreData(data) {
                    completion(.success(calendar))
                } else {
                    completion(.failure(NSError(domain: "DataError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to decode calendar data."])))
                }
            } else {
                completion(.failure(NSError(domain: "NotFoundError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Calendar not found."])))
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

    
    // MARK: - Update Calendar Through Firestore
    
    
    
    
    // MARK: - Add Calendar Through Firestore
    // Needs To Make Sure This Isnt A time thats already there
    
    
    // MARK: - 

    
    
}
