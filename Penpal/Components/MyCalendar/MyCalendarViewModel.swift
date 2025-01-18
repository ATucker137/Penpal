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
    
    @Published var meeting: [Meeting] = [] // But Now Since Not using Meetings and USing IDs this might be more complex?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let service: CalendarService
    
    // MARK: - Initializer
    
    init(service: CalendarService = CalendarService()) {
        self.service = service
        fetchCalendar()
    }
    
    // MARK: - Fetch Events
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
    

    
    // MARK: - Save Event
    func saveCalendar(_ meeting: Meeting) {
        
    }
    
    // MARK: - Invitation Handling
    func acceptInvitation(_ meeting: Meeting) {
        // TODO: Implement invitation acceptance logic
    }
    
    func declineInvitation(_ meeting: Meeting) {
        // TODO: Implement invitation decline logic
    }

    
    
}
