//
//  Meeting.swift
//  Penpal
//
//  Created by Austin William Tucker on 12/29/24.
//


// MARK: - Meeting Class - Model of the Meeting within the MVVM Design Structure
class Meeting: Identifiable, Codable {
    
    // MARK: - Properties
    var id: String
    var title: String
    var description: String
    var suggestedTopicsIds: [String] // PAss in the id because it will be quick to query
    var datetime: String
    var createdByProfileId: String
    var notes: String
    var meetinglink: String
    var passcode: String
    var participants: [String]
    var status: String // Example pending,accepted,denied
    
    // Maybe within init participants: [String]? = nil, // Optional, defaults to including the creator
    // Maybe within init status:         status: String = "pending"
    //MARK: - Initializer
    init(id: String, title: String, description: String, suggestedTopicsIds: [String], datetime: String, createdByProfileId: String, notes: String, meetinglink: String, passcode: String, participants: [String], status: String) {
        self.id = id
        self.title = title
        self.description = description
        self.suggestedTopicsIds = suggestedTopicsIds
        self.datetime = datetime
        self.createdByProfileId = createdByProfileId
        self.notes = notes
        self.meetinglink = meetinglink
        self.passcode = passcode
        self.participants = participants
        self.status = status
    }
    
    // MARK: - Will Interact With the Fetch Meeting To Ensure that its properly being fetched with correct datatypes
    // This function will populate a Meeting from the data received from Firestore
    //NOTE Verify this with CHatGPT
    static func fromFireStoreData(_ data: [String: Any]) -> Meeting {
        guard let id = data["id"] as? String,
              let title = data["title"] as? String,
              let description = data["description"] as? String,
              let suggestedTopicsIds = data["suggestedTopicsIds"] as? [String],
              let datetime = data["datetime"] as? String,
              let createdByProfileId = data["createdByProfileId"] as? String,
              let notes = data["notes"] as? String,
              let meetinglink = data["meetinglink"] as? String,
              let passcode = data["passcode"] as? String,
              let participants = data["participants"] as? [String],
              let status = data["status"] else {
            return nil
    }
    return Meeting(id: id, title: title, description: description, suggestedTopicsIds: suggestedTopicsIds, datetime: datetime, createdByProfileId: createdByProfileId, notes: notes, meetinglink: meetinglink, passcode: passcode, participants: participants, status: status)
    }
    
    // MARK: - Putting the Meeting into FireStore
    func toFireStoreData() -> [String: Any] {
        return [
            "id" : id,
            "title" : title,
            "description" : description,
            "suggestedTopicsIds" : suggestedTopicsIds,
            "datetime" : datetime,
            "createdByProfileId" : createdByProfileId,
            "notes" : notes,
            "meetinglink" : meetinglink,
            "passcode" : passcode,
            "participants" : participants,
            "status" : status,
        ]
    }
    
    
}
