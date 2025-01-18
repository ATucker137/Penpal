//
//  MyCalendar.swift
//  Penpal
//
//  Created by Austin William Tucker on 12/1/24.
//

// MARK: - MyCalendar - Model of a Users Calendar in the MVVM Structure
class MyCalendar: Codable, Identifiable {
    
    // MARK: - Properties
    var id: String
    var userId: String
    var meetings: [Meeting]
    
    
    // MARK: - Initializer
    init(id: String, userId: String, meetings: [Meeting]) {
        self.id = id
        self.userId = userId
        self.meetings = meetings
    }
    
    
    //NOTE Verify this with CHatGPT
    // MARK: - Method to take Collection from FireStore and put into Calendar Model
    func fromFireStoreData(_ data: [String: Any]) -> MyCalendar? {
        
        guard let id = data["id"] as? String,
              let userId = data["userId"] as? String,
              let meetings = data["meetings"] as? [Meeting] else {
            return nil
        }
        return MyCalendar(id: id, userId: userId, meetings: meetings)
    }
    
    
    
}
