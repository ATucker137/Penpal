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
func debugLog(_ message: String) {
    #if DEBUG
    print(message)
    #endif
}

enum LogLevel {
    case info
    case warning
    case error
}

class MyCalendarViewModel: ObservableObject {
    
    // MARK: - Published Properties
    //TODO: - Should this contain Meeting objects or Meeting id"S
    @Published var meetings: [MeetingModel] = [] // But Now Since Not using Meetings and USing IDs this might be more complex?
    @Published var penpalMap: [String: PenpalsModel] = [:]
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var meetingViewModel: MeetingViewModel
    
    // MARK: - Private Properties
    private let sqliteManager = SQLiteManager() // Local storage

    private var userId: String? {
        return UserSession.shared.userId
    }
    private let service: MyCalendarService
    private let category = "Calendar ViewModel"

    
    // MARK: - Initializer
    
    init(service: MyCalendarService = MyCalendarService()) {
        self.service = service
        fetchCalendar()
    }
    
    
    
    // MARK: - Fetch Events - might not need this due to fetchAllMeetings below
    func fetchCalendar() {
        guard let userId = userId else {
            LoggerService.shared.log(.error, "User ID not available", category: category)
            return
        }
        isLoading = true
        LoggerService.shared.log(.info, "Fetching calendar for user: \(userId)", category: category)

        service.fetchMyCalendar(for: userId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let fetchedMeetings):
                    self?.meetings = fetchedMeetings
                    self?.sqliteManager.cacheMeetings(fetchedMeetings)  // Use cacheMeetings or equivalent method
                    LoggerService.shared.log(.info, "Successfully fetched \(fetchedMeetings.count) meetings.", category: self?.category)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    LoggerService.shared.log(.error, "Failed to fetch calendar: \(error.localizedDescription)", category: self?.category)
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
                    LoggerService.shared.log(.info, "Fetched \(fetchedMeetings.count) meetings from Firestore.", category: self?.category ?? "Unknown")
                    self?.sqliteManager.cacheMeetings(fetchedMeetings)

                case .failure(let error):
                    self?.errorMessage = "Error fetching meetings: \(error.localizedDescription)"
                    LoggerService.shared.log(.error, "Error fetching meetings: \(error.localizedDescription)", category: self?.category ?? "Unknown")
                }
            }
        }
    }

    
    // MARK: - Save Event -- AShould Be Refactored For Calendar
    func saveCalendar(_ meeting: MeetingModel) {
        // Save to Firestore via your service
        service.saveMeeting(meeting) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Save to SQLite after remote save
                    LoggerService.shared.log(.info, "Saved calendar with Meeting ID \(meeting.id)", category: self?.category ?? "Unknown")
                    self?.sqliteManager.insertMeeting(meeting)
                    self?.fetchAllMeetings() // Refresh from Firestore
                case .failure(let error):
                    self?.errorMessage = "Error saving meeting: \(error.localizedDescription)"
                    LoggerService.shared.log(.error, "Error saving meeting: \(error.localizedDescription)", category: self?.category ?? "Unknown")
                }
            }
        }
        
    }
    
   
    // MARK: - Update Calendar
    func updateMyCalendar(for userId: String) {
        LoggerService.shared.log(.info, "Attempting to update calendar for user ID: \(userId)", category: category)
        
        service.fetchMyCalendar(for: userId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let fetchedMeetings):
                    self?.meetings = fetchedMeetings
                    LoggerService.shared.log(.info, "Successfully updated calendar for user ID: \(userId)", category: self?.category ?? "Unknown")
                case .failure(let error):
                    self?.errorMessage = "Failed to update calendar: \(error.localizedDescription)"
                    LoggerService.shared.log(.error, "Failed to update calendar for user ID \(userId): \(error.localizedDescription)", category: self?.category ?? "Unknown")
                }
            }
        }
    }




    
    // MARK: - Load Meetings from SQLite
    func loadMeetingsFromCache() {
        log(.info, "Loading meetings from local SQLite cache.")
        
        DispatchQueue.main.async {
            self.meetings = self.sqliteManager.fetchMeetings()
            LoggerService.shared.log(.info, "Loaded \(self.meetings.count) meetings from SQLite cache.", category: self.category)
        }
    }
    
    //MARK: - Fetch Penpals
    func fetchPenpals() {
        guard let userId = userId else {
            LoggerService.shared.log(.error, "User ID not available", category: category)
            return
        }
        isLoading = true
    }
    
    //MARK: - Tag Meeting Id To Penpal Name

    
}
