//
//  MeetingService.swift
//  Penpal
//
//  Created by Austin William Tucker on 12/29/24.
//
import FirebaseFirestoreInternal
import FirebaseFirestoreInternalWrapper
import FirebaseFirestore
import Firebase


// TODO: Batch Operation will probably be needed for updating a user schedule. Would also probably need the user to be able to acccept the meeting as well
// TODO: - Create Os Logging For Debuging as well print for debug mode as well



class MeetingService {
    
    private let db = Firebase.firestore()
    
    private let collectionName = "meeting"
    private let category = "Meeting Service"
    
    
    // MARK: - Create Meeting Through Firestore
    func createMeeting(meeting: MeetingModel) async throws {
        LoggerService.shared.log(.info, "Creating meeting with id \(meeting.id)", category: self.category)
        do {
            // Firestore has a modern `async` API that we can use directly
            try db.collection(collectionName).document(meeting.id).setData(from: meeting)
            LoggerService.shared.log(.info, "Successfully created meeting \(meeting.id)", category: self.category)
        } catch {
            LoggerService.shared.log(.error, "Failed to create meeting \(meeting.id): \(error.localizedDescription)", category: self.category)
            throw error // Re-throw the error for the calling ViewModel to handle
        }
    }
    
    // MARK: - Delete Meeting Through Firestore
    func deleteMeeting(meetingId: String) async throws {
        LoggerService.shared.log(.info, "Deleting meeting with id \(meetingId)", category: self.category)
        do {
            try await db.collection(collectionName).document(meetingId).delete()
            LoggerService.shared.log(.info, "Successfully deleted meeting \(meetingId)", category: self.category)
        } catch {
            LoggerService.shared.log(.error, "Failed to delete meeting \(meetingId): \(error.localizedDescription)", category: self.category)
            throw error
        }
    }

    // MARK: - // The catch let error will never be triggered because Firestor wont throw errors The setData(from:merge:) method
    func updateMeeting(meeting: MeetingModel) async throws {
        LoggerService.shared.log(.info, "Updating meeting with id \(meeting.id)", category: self.category)
        do {
            try await db.collection(collectionName).document(meeting.id).setData(from: meeting, merge: true)
            LoggerService.shared.log(.info, "Successfully updated meeting \(meeting.id)", category: self.category)
        } catch {
            LoggerService.shared.log(.error, "Failed to update meeting \(meeting.id): \(error.localizedDescription)", category: self.category)
            throw error
        }
    }
        
    
    // MARK: - Fetch Meeting Through Firestore
    func fetchMeeting(meetingId: String) async throws -> MeetingModel {
        LoggerService.shared.log(.info, "Fetching meeting with id \(meetingId)", category: self.category)
        do {
            let snapshot = try await db.collection(collectionName).document(meetingId).getDocument()
            guard snapshot.exists else {
                let err = NSError(domain: self.category, code: 404, userInfo: [NSLocalizedDescriptionKey: "Meeting not found."])
                LoggerService.shared.log(.error, "Meeting \(meetingId) not found.", category: self.category)
                throw err
            }
            let meeting = try snapshot.data(as: MeetingModel.self)
            LoggerService.shared.log(.info, "Successfully fetched meeting \(meetingId)", category: self.category)
            return meeting
        } catch {
            LoggerService.shared.log(.error, "Failed to fetch meeting \(meetingId): \(error.localizedDescription)", category: self.category)
            throw error
        }
    }
    
    
    // Note: - First implementation of Batch Processing - Detailed Explanation Below
    // MARK: -  Accept Meeting Through Firestore
    func acceptMeeting(userId: String, meetingId: String) async throws {
        LoggerService.shared.log(.info, "Attempting to accept meeting with id \(meetingId) for user \(userId)", category: self.category)
        
        let meetingRef = db.collection(collectionName).document(meetingId)
        
        // Use the modern `async` runTransaction method
        try await db.runTransaction { transaction in
            // Use `try` to get the document from the transaction
            let meetingSnapshot = try transaction.getDocument(meetingRef)
            
            guard var meeting = try meetingSnapshot.data(as: MeetingModel.self) else {
                throw NSError(domain: "MeetingService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Meeting not found."])
            }
            
            if meeting.status == "pending" {
                meeting.status = "accepted"
                if !meeting.participants.contains(userId) {
                    meeting.participants.append(userId)
                }
                
                // Use `try` to set the data back in the transaction
                try transaction.setData(from: meeting, forDocument: meetingRef, merge: true)
                LoggerService.shared.log(.info, "Successfully accepted meeting \(meetingId)", category: self.category)
            } else {
                throw NSError(domain: "MeetingService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Meeting cannot be accepted."])
            }
        }
    }

    
    // MARK: - Fetch All Meetings Through Firestore
    func fetchAllMeetings() async throws -> [MeetingModel] {
        LoggerService.shared.log(.info, "Fetching all meetings", category: self.category)
        do {
            let snapshot = try await db.collection(collectionName).getDocuments()
            let meetings = try snapshot.documents.compactMap { document -> MeetingModel? in
                return try document.data(as: MeetingModel.self)
            }
            LoggerService.shared.log(.info, "Successfully fetched \(meetings.count) meetings", category: self.category)
            return meetings
        } catch {
            LoggerService.shared.log(.error, "Failed to fetch meetings: \(error.localizedDescription)", category: self.category)
            throw error
        }
    }

        
        
    
    // MARK: - Function For Generating the Zoom Link
    func generateZoomMeeting() {
        
    }
    // MARK: - Add Discussion Topics To Meeting
    func addDiscussionTopicsToMeeting(discussionTopic: String, meetingId: String) async throws {
        LoggerService.shared.log(.info, "Adding discussion topic to meeting \(meetingId): \(discussionTopic)", category: self.category)
        
        do {
            var meeting = try await self.fetchMeeting(meetingId: meetingId)
            
            var discussionTopics = meeting.discussionTopics ?? [:]
            let newTopic = "New Topic"
            
            if discussionTopics[newTopic] == nil {
                discussionTopics[newTopic] = []
            }
            
            discussionTopics[newTopic]?.append(discussionTopic)
            meeting.discussionTopics = discussionTopics
            
            try await self.updateMeeting(meeting: meeting)
            
            LoggerService.shared.log(.info, "Successfully added discussion topic to meeting \(meetingId)", category: self.category)
        } catch {
            LoggerService.shared.log(.error, "Failed to add discussion topics to meeting \(meetingId): \(error.localizedDescription)", category: self.category)
            throw error
        }
    }
    // MARK: - Add Function For Editing Discussion Topics
    func editDiscussionTopic(meetingId: String, oldTopic: String, newTopic: String) async throws {
        LoggerService.shared.log(.info, "Editing discussion topic for meeting \(meetingId): \(oldTopic) to \(newTopic)", category: self.category)
        do {
            var meeting = try await self.fetchMeeting(meetingId: meetingId)
            
            var discussionTopics = meeting.discussionTopics ?? [:]
            
            // Assuming the `oldTopic` is a key in the dictionary
            if let topics = discussionTopics[oldTopic] {
                discussionTopics[newTopic] = topics
                discussionTopics.removeValue(forKey: oldTopic)
            }
            
            meeting.discussionTopics = discussionTopics
            
            try await self.updateMeeting(meeting: meeting)
            
            LoggerService.shared.log(.info, "Successfully edited discussion topic for meeting \(meetingId)", category: self.category)
        } catch {
            LoggerService.shared.log(.error, "Failed to edit discussion topic for meeting \(meetingId): \(error.localizedDescription)", category: self.category)
            throw error
        }
    }
    
}
