//
//  MeetingViewModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 12/29/24.
//
import Foundation

class MeetingViewModel: ObservableObject {
    @Published var meeting: MeetingModel? // Optional to handle no meeting state
    @Published var isLoading = false
    @Published var errorMessage: String?

    
    // MARK: - Private Properties
    private let meetingService = MeetingService
    private var userId: String? {
        return UserSession.shared.userId
    }
    private let category = "MeetingViewModel" // Logger category

    
    // MARK: - Initializer
    
    init(meetingService: MeetingService = MeetingService()) {
        self.meetingService = meetingService
    }
    

    // MARK: - Helper Methods
    private func startLoading() {
        isLoading = true
        errorMessage = nil
        LoggerService.shared.log(.info, "Started loading...", category: self.category)
    }

    private func stopLoading() {
        isLoading = false
        LoggerService.shared.log(.info, "Stopped loading.", category: self.category)

    }

    // MARK: - Fetch Meeting
    func fetchMeeting(meetingId: String) async {
            startLoading()
            do {
                let fetchedMeeting = try await meetingService.fetchMeeting(meetingId: meetingId)
                self.meeting = fetchedMeeting
                LoggerService.shared.log(.info, "Fetched meeting with id: \(meetingId)", category: self.category)
            } catch {
                // Error handling is now a simple `catch` block
                LoggerService.shared.log(.error, "Failed to fetch meeting with id \(meetingId): \(error.localizedDescription)", category: self.category)
                self.errorMessage = error.localizedDescription
            }
            stopLoading()
        }

    // MARK: - Create Meeting
    func createMeeting(meeting: MeetingModel) async {
        startLoading()
        do {
            try await meetingService.createMeeting(meeting: meeting)
            self.meeting = meeting
            LoggerService.shared.log(.info, "Created meeting with id: \(meeting.id)", category: self.category)
        } catch {
            LoggerService.shared.log(.error, "Failed to create meeting: \(error.localizedDescription)", category: self.category)
            self.errorMessage = error.localizedDescription
        }
        stopLoading()
    }

    // MARK: - Delete Meeting
    func deleteMeeting(meetingId: String) async {
        startLoading()
        do {
            try await meetingService.deleteMeeting(meetingId: meetingId)
            self.meeting = nil // Clear the current meeting after deletion
            LoggerService.shared.log(.info, "Deleted meeting with id: \(meetingId)", category: self.category)
        } catch {
            LoggerService.shared.log(.error, "Failed to delete meeting with id \(meetingId): \(error.localizedDescription)", category: self.category)
            self.errorMessage = error.localizedDescription
        }
        stopLoading()
    }

    // MARK: - Update Meeting
    func updateMeeting(meeting: MeetingModel) async {
        startLoading()
        do {
            try await meetingService.updateMeeting(meeting: meeting)
            self.meeting = meeting
            LoggerService.shared.log(.info, "Updated meeting with id: \(meeting.id)", category: self.category)
        } catch {
            LoggerService.shared.log(.error, "Failed to update meeting with id \(meeting.id): \(error.localizedDescription)", category: self.category)
            self.errorMessage = error.localizedDescription
        }
        stopLoading()
    }
    
    // MARK: - Invitation Handling
    // Add the invitation depending on the user id
    func acceptMeeting(meetingId: String) async {
        do {
            // Delegate the action to MeetingViewModel (remote Firestore)
            guard let userId = userId else {
                self.errorMessage = "User ID not available."
                return
            }
            try await meetingService.acceptMeeting(userId: userId, meetingId: meetingId)
            // Update local SQLite cache
            LoggerService.shared.log(.info, "Accepted meeting with id: \(meetingId)", category: self.category)
            self.sqliteManager.updateMeetingStatus(meetingId: meetingId, status: "accepted")
            await self.fetchCalendar() // Call the new async version
        } catch {
            LoggerService.shared.log(.error, "Failed to accept meeting with id \(meetingId): \(error.localizedDescription)", category: self.category)
            self.errorMessage = error.localizedDescription
        }
    }

    
    // Add the invitation depending on user id
    // TODO: - Need to add to Service Layer
    func declineMeeting(_ meeting: Meeting) async {
        do {
            // Update status in Firestore
            try await meetingService.updateMeetingStatus(meetingId: meeting.id, status: "declined")
            LoggerService.shared.log(.info, "Declined meeting with id: \(meeting.id)", category: self.category)
            
            var declinedMeeting = meeting
            declinedMeeting.status = "declined"
            
            // Save updated meeting locally
            self.sqliteManager.updateMeeting(declinedMeeting.toMeetingModel())
            
            // Optionally update UI
            await self.fetchAllMeetings()
        } catch {
            LoggerService.shared.log(.error, "Failed to decline meeting with id \(meeting.id): \(error.localizedDescription)", category: self.category)
            self.errorMessage = error.localizedDescription
        }
    }
}
