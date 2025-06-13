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
    
    // MARK: - Initializer
    
    init(meetingService: MeetingService = MeetingService()) {
        self.meetingService = meetingService
    }
    

    // MARK: - Helper Methods
    private func startLoading() {
        isLoading = true
        errorMessage = nil
    }

    private func stopLoading() {
        isLoading = false
    }

    // MARK: - Fetch Meeting
    func fetchMeeting(meetingId: String) {
        startLoading()
        meetingService.fetchMeeting(meetingId: meetingId) { [weak self] result in
            DispatchQueue.main.async {
                self?.stopLoading()
                switch result {
                case .success(let fetchedMeeting):
                    self?.meeting = fetchedMeeting
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Create Meeting
    func createMeeting(meeting: MeetingModel) {
        startLoading()
        meetingService.createMeeting(meeting: meeting) { [weak self] result in
            DispatchQueue.main.async {
                self?.stopLoading()
                switch result {
                case .success:
                    self?.meeting = meeting
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Delete Meeting
    func deleteMeeting(meetingId: String) {
        startLoading()
        meetingService.deleteMeeting(meetingId: meetingId) { [weak self] result in
            DispatchQueue.main.async {
                self?.stopLoading()
                switch result {
                case .success:
                    self?.meeting = nil // Clear the current meeting after deletion
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Update Meeting
    func updateMeeting(meeting: MeetingModel) {
        startLoading()
        meetingService.updateMeeting(meeting: meeting) { [weak self] result in
            DispatchQueue.main.async {
                self?.stopLoading()
                switch result {
                case .success:
                    self?.meeting = meeting
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Invitation Handling
    // Add the invitation depending on the user id
    func acceptMeeting(meetingId: String) {
        // Delegate the action to MeetingViewModel (remote Firestore)
        meetingService.acceptMeeting(userId: userId, meetingId: meetingId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Update local SQLite cache
                    self?.sqliteManager.updateMeetingStatus(meetingId: meetingId, status: "accepted")
                    self?.fetchCalendar() // Re-fetch or update state
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    
    // Add the invitation depending on user id
    // TODO: - Need to add to Service Layer
    func declineMeeting(_ meeting: Meeting) {
        // Update status in Firestore
        meetingService.updateMeetingStatus(meetingId: meeting.id, status: "declined") { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    var declinedMeeting = meeting
                    declinedMeeting.status = "declined"

                    // Save updated meeting locally
                    self?.sqliteManager.updateMeeting(declinedMeeting.toMeetingModel())

                    // Optionally update UI
                    self?.fetchAllMeetings()

                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

}
