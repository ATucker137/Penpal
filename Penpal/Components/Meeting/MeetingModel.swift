//
//  MeetingModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 12/29/24.
//
import Foundation
import SQLite3

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
    var isSynced: Bool // isSynced to Firestore
    
    // Maybe within init participants: [String]? = nil, // Optional, defaults to including the creator
    // Maybe within init status:         status: String = "pending"
    //MARK: - Initializer
    init(id: String, title: String, description: String, discussionTopics: [String: [String]], datetime: String, createdByProfileId: String, notes: String, meetinglink: String, passcode: String, participants: [String] = [], status: String = "pending", isSynced: Bool = false) {
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
        self.isSynced = isSynced
    }

    
    // MARK: - Will Interact With the Fetch Meeting To Ensure that its properly being fetched with correct datatypes
    // This function will populate a Meeting from the data received from Firestore
    static func fromFireStoreData(_ data: [String: Any]) -> MeetingModel? {
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
              let status = data["status"] as? String,
              let isSynced = data["isSynced"] as? Bool else {
            return nil
        }

        return MeetingModel(id: id, title: title, description: description, discussionTopics: discussionTopics, datetime: datetime, createdByProfileId: createdByProfileId, notes: notes, meetinglink: meetinglink, passcode: passcode, participants: participants, status: status, isSynced: isSynced)
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
            "isSynced" : isSynced
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
            "status": status,
            "isSynced": isSynced
        ]
    }

    // MARK: - Convert SQLite Data to MeetingModel
    static func fromSQLiteData(statement: OpaquePointer) -> MeetingModel? {
        guard let idPtr = sqlite3_column_text(statement, 0),
              let titlePtr = sqlite3_column_text(statement, 1),
              let descriptionPtr = sqlite3_column_text(statement, 2),
              let discussionTopicsPtr = sqlite3_column_text(statement, 3),
              let datetimePtr = sqlite3_column_text(statement, 4),
              let createdByProfileIdPtr = sqlite3_column_text(statement, 5),
              let notesPtr = sqlite3_column_text(statement, 6),
              let meetinglinkPtr = sqlite3_column_text(statement, 7),
              let passcodePtr = sqlite3_column_text(statement, 8),
              let participantsPtr = sqlite3_column_text(statement, 9),
              let statusPtr = sqlite3_column_text(statement, 10) else {
            return nil
        }
        
        let id = String(cString: idPtr)
        let title = String(cString: titlePtr)
        let description = String(cString: descriptionPtr)
        let discussionTopicsString = String(cString: discussionTopicsPtr)
        let datetime = String(cString: datetimePtr)
        let createdByProfileId = String(cString: createdByProfileIdPtr)
        let notes = String(cString: notesPtr)
        let meetinglink = String(cString: meetinglinkPtr)
        let passcode = String(cString: passcodePtr)
        let participantsString = String(cString: participantsPtr)
        let status = String(cString: statusPtr)
        
        let discussionTopicsData = discussionTopicsString.data(using: .utf8) ?? Data()
        let discussionTopics = (try? JSONSerialization.jsonObject(with: discussionTopicsData, options: []) as? [String: [String]]) ?? [:]

        let participantsData = participantsString.data(using: .utf8) ?? Data()
        let participants = (try? JSONSerialization.jsonObject(with: participantsData, options: []) as? [String]) ?? []

        let isSynced = sqlite3_column_int(statement, 11) == 1

        return MeetingModel(id: id, title: title, description: description, discussionTopics: discussionTopics, datetime: datetime, createdByProfileId: createdByProfileId, notes: notes, meetinglink: meetinglink, passcode: passcode, participants: participants, status: status, isSynced: isSynced)
    }


    
}
