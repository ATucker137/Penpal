//
//  MeetingModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 12/29/24.
//


// MARK: - Meeting Class - Model of the Meeting within the MVVM Design Structure
class MeetingModel: Identifiable, Codable {
    
    // MARK: - Properties
    var id: String
    var title: String
    var description: String
    var discussionTopics: [String: [String]] // Stores topics and their selected subcategories
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
    init(id: String, title: String, description: String, discussionTopics: [String : [String]], datetime: String, createdByProfileId: String, notes: String, meetinglink: String, passcode: String, participants: [String], status: String) {
        self.id = id
        self.title = title
        self.description = description
        self.discussionTopics = discussionTopics
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
    static func fromFireStoreData(_ data: [String: Any]) -> MeetingModel {
        guard let id = data["id"] as? String,
              let title = data["title"] as? String,
              let description = data["description"] as? String,
              let discussionTopics = data["discussionTopics"] as? [String: [String]],
              let datetime = data["datetime"] as? String,
              let createdByProfileId = data["createdByProfileId"] as? String,
              let notes = data["notes"] as? String,
              let meetinglink = data["meetinglink"] as? String,
              let passcode = data["passcode"] as? String,
              let participants = data["participants"] as? [String],
              let status = data["status"] as? String
        else {
            return nil
    }
        return MeetingModel(id: id, title: title, description: description, discussionTopics: discussionTopics, datetime: datetime, createdByProfileId: createdByProfileId, notes: notes, meetinglink: meetinglink, passcode: passcode, participants: participants, status: status)
    }
    
    // MARK: - Putting the Meeting into FireStore
    func toFireStoreData() -> [String: Any] {
        return [
            "id" : id,
            "title" : title,
            "description" : description,
            "discussionTopics" : discussionTopics,
            "datetime" : datetime,
            "createdByProfileId" : createdByProfileId,
            "notes" : notes,
            "meetinglink" : meetinglink,
            "passcode" : passcode,
            "participants" : participants,
            "status" : status,
        ]
    }
    
    
    // MARK: - Convert MeetingModel to SQLite Data
    func toSQLiteData() -> [String: Any] {
        let discussionTopicsJSON = try? JSONSerialization.data(withJSONObject: discussionTopics, options: [])
        let discussionTopicsString = discussionTopicsJSON != nil ? String(data: discussionTopicsJSON!, encoding: .utf8) : "{}"
        
        let participantsJSON = try? JSONSerialization.data(withJSONObject: participants, options: [])
        let participantsString = participantsJSON != nil ? String(data: participantsJSON!, encoding: .utf8) : "[]"

        return [
            "id": id,
            "title": title,
            "description": description,
            "discussionTopics": discussionTopicsString ?? "{}",
            "datetime": datetime,
            "createdByProfileId": createdByProfileId,
            "notes": notes,
            "meetinglink": meetinglink,
            "passcode": passcode,
            "participants": participantsString ?? "[]",
            "status": status
        ]
    }

    // MARK: - Convert SQLite Data to MeetingModel
    static func fromSQLiteData(statement: OpaquePointer) -> MeetingModel? {
        guard let id = sqlite3_column_text(statement, 0),
              let title = sqlite3_column_text(statement, 1),
              let description = sqlite3_column_text(statement, 2),
              let discussionTopicsString = sqlite3_column_text(statement, 3),
              let datetime = sqlite3_column_text(statement, 4),
              let createdByProfileId = sqlite3_column_text(statement, 5),
              let notes = sqlite3_column_text(statement, 6),
              let meetinglink = sqlite3_column_text(statement, 7),
              let passcode = sqlite3_column_text(statement, 8),
              let participantsString = sqlite3_column_text(statement, 9),
              let status = sqlite3_column_text(statement, 10)
        else {
            return nil
        }

        // Convert JSON Strings back to Dictionary and Array
        let discussionTopicsData = String(cString: discussionTopicsString).data(using: .utf8) ?? Data()
        let discussionTopics = (try? JSONSerialization.jsonObject(with: discussionTopicsData, options: []) as? [String: [String]]) ?? [:]

        let participantsData = String(cString: participantsString).data(using: .utf8) ?? Data()
        let participants = (try? JSONSerialization.jsonObject(with: participantsData, options: []) as? [String]) ?? []

        return MeetingModel(
            id: String(cString: id),
            title: String(cString: title),
            description: String(cString: description),
            discussionTopics: discussionTopics,
            datetime: String(cString: datetime),
            createdByProfileId: String(cString: createdByProfileId),
            notes: String(cString: notes),
            meetinglink: String(cString: meetinglink),
            passcode: String(cString: passcode),
            participants: participants,
            status: String(cString: status)
        )
    }

    
}
