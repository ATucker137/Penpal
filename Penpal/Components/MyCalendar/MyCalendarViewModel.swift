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
    
    @Published var events: [Meeting] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let service: CalendarService
    
    // MARK: - Initializer
    
    init(service: CalendarService = CalendarService()) {
        self.service = service
        fetchEvents()
    }
    
    // MARK: - Fetch Events
    
    func fetchEvents() {
        isLoading = true
        service.fetchEvents { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let events):
                    self?.events = events
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Save Event
    
    func saveEvent(_ event: CalendarEvent) {
        isLoading = true
        service.saveEvent(event) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.fetchEvents() // Refresh the list of events after saving
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Delete Event
    
}
