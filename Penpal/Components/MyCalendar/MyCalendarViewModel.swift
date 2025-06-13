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
    private let sqliteManager = SQLiteManager() // Local storage

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
                    self?.sqliteManager.insertMeeting(meeting)
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
                    self?.sqliteManager.cacheMeetings(fetchedMeetings)

                case .failure(let error):
                    self?.errorMessage = "Error fetching meetings: \(error.localizedDescription)"
                }
            }
        }
    }

    
    // MARK: - Save Event
    func saveCalendar(_ meeting: Meeting) {
        // Save to Firestore via your service
        service.saveMeeting(meeting) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Save to SQLite after remote save
                    self?.sqliteManager.insertMeeting(meeting)
                    self?.fetchAllMeetings() // Refresh from Firestore
                case .failure(let error):
                    self?.errorMessage = "Error saving meeting: \(error.localizedDescription)"
                }
            }
        }
        
    }
    
    
    
    // MARK: - Load meetings from SQLite
    func loadMeetingsFromCache() {
        DispatchQueue.main.async {
            self.meetings = self.sqliteManager.fetchMeetings()
        }
    }
    
}
