//
//  MyCalendarViewModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//

import Foundation
import Combine

// MARK: - CalendarViewModel


// TODO: needs the specificuser Id of the profile

class MyCalendarViewModel: ObservableObject {
    
    // MARK: - Published Properties
    //TODO: - Should this contain Meeting objects or Meeting id"S
    @Published var meeting: [Meeting] = [] // But Now Since Not using Meetings and USing IDs this might be more complex?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var meetingViewModel: MeetingViewModel
    
    // MARK: - Private Properties
    
    private var userId: String? {
        return UserSession.shared.userId
    }
    private let service: MyCalendarService
    
    // MARK: - Initializer
    
    init(service: MyCalendarService = MyCalendarService()) {
        self.service = service
        fetchCalendar()
    }
    
    // MARK: - Fetch Events - might not need this due to fetchAllMeetings below
    func fetchCalendar() {
        isLoading = true
        service.fetchCalendar { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let meeting):
                    self?.meeting = meeting
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Fetch all meetings from Firestore
    func fetchAllMeetings() {
        meetingService.fetchAllMeetings { [weak self] result in
            DispatchQueue.main.async { // Ensure updates happen on the main thread
                switch result {
                case .success(let fetchedMeetings):
                    self?.meetings = fetchedMeetings // Update the published meetings
                case .failure(let error):
                    self?.errorMessage = "Error fetching meetings: \(error.localizedDescription)"
                }
            }
        }
    }

    
    // MARK: - Save Event
    func saveCalendar(_ meeting: Meeting) {
        
    }
    
    // MARK: - Invitation Handling
    // Add the invitation depending on the user id
    // TODO: - Need to add to Service Layer
    func acceptMeeting(meetingId: String) {
        // Delegate the action to MeetingViewModel
        meetingViewModel.acceptMeeting(userId: userId, meetingId: meetingId){ [weak self] result in
            switch result {
            case .success:
                // Optionally handle any UI updates or refresh calendar here
                self?.fetchCalendar()  // Re-fetch calendar or update state
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
            }
        }
    }
    
    // Add the invitation depending on user id
    // TODO: - Need to add to Service Layer
    // Doesn't really need to be
    func declineInvitation(_ meeting: Meeting) {
        // TODO: Implement invitation decline logic
        
        // For The User that we have
        
        // Append the Meeting To The Users Calendar
        
        // Changing the status as wellfrom pending to declined
        
    }
    
}
