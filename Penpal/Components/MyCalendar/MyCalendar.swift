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
    var meetingIds: [String] // No longers going to store List of meetings, need to store list of ids
    
    
    // MARK: - Initializer
    init(id: String, userId: String, meetingIds: [String]) {
        self.id = id
        self.userId = userId
        self.meetingIds = meetingIds
    }
    
    
    //NOTE Verify this with CHatGPT
    // MARK: - Method to take Collection from FireStore and put into Calendar Model
    static func fromFireStoreData(_ data: [String: Any]) -> MyCalendar? {
        
        guard let id = data["id"] as? String,
              let userId = data["userId"] as? String,
              let meetingIds = data["meetingIds"] as? [String] else {
            return nil
        }
        return MyCalendar(id: id, userId: userId, meetingIds: meetingIds)
       
    }
    
    
    
}
