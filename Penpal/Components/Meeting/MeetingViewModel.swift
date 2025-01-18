//
//  MeetingViewModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 12/29/24.
//
import Foundation

class MeetingViewModel: ObservableObject {
    @Published var meeting: Meeting? // Optional to handle no meeting state
    @Published var isLoading = false
    @Published var errorMessage: String?

    
    // MARK: - Private Properties
    private let meetingService = MeetingService
    
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
    func createMeeting(meeting: Meeting) {
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
    func updateMeeting(meeting: Meeting) {
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
}
