//
//  CalendarView.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//

// What A Calendar View Should Have - Be Similar to Italki
/*
 
 Have Calendar Present as half the screen as a monthly view
 
 Be able to scroll the monthly view
 
 For each of the respective days - have dots if the user has a meeting on that day
 
 When clicking on day with dot, have card for the time
 And then navigation to details of the Meeting, that can be a separate view, so that would be done by linking the MeetingView()
 Example
 NavigationLink("Go to Second View") {
                 SecondView()
             }
 
 
 */

import SwiftUI

struct MyCalendarView: View {
    @StateObject private var viewModel = MyCalendarViewModel()
    @EnvironmentObject var userSession: UserSession
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTab: Tab

    var body: some View {
        
        VStack {
            if let userId = userSession.userId {
                Text("Calendar for User ID: \(userId)")
                // Use the userId in your ViewModel or Firestore queries
            } else {
                Text("Please log in to view your calendar.")
            }
        }.toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                dismiss() // Navigate back to CalendarView
                            }) {
                                HStack {
                                    Image(systemName: "arrow.backward")
                                    Text("Back")
                                }
                                .foregroundColor(.blue) // Customize color
                            }
                        }
            
        }
       
        NavigationView {
            
            NavigationLink("Meeting Overview") {
                MeetingView(meetingId: "mock-meeting-id") // Pass a real meeting ID dynamically
            }
            
            
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading Events...")
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                } else {
                    List(viewModel.events) { event in
                        VStack(alignment: .leading) {
                            Text(event.title)
                                .font(.headline)
                            Text("\(event.startDate, formatter: DateFormatter.shortDate) - \(event.endDate, formatter: DateFormatter.shortDate)")
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("Calendar")
            .toolbar {
                Button(action: {
                    // Example: Add a new event
                    let newEvent = CalendarEvent(
                        eventId: UUID().uuidString, // Unique ID
                        title: "New Event", // Title of the event
                        description: "This is a test event", // Event description
                        startTime: Date(), // Start time
                        startDate: Date(), // Start date
                        endTime: Date().addingTimeInterval(3600), // End time (1 hour later)
                        endDate: Date().addingTimeInterval(3600), // End date (same as end time for now)
                        participants: ["user1", "user2"], // Example participants
                        reminder: true, // Reminder enabled
                        notes: "Don't forget this event!", // Notes about the event
                        attendees: ["attendee1@example.com", "attendee2@example.com"], // Example attendees
                        userId: userSession.userId // Use the logged-in user's ID from UserSession
                    )
                    viewModel.saveEvent(newEvent)
                }) {
                    Image(systemName: "plus")
                }
            }
        }
    }.onAppear {
        viewModel.fetchAllMeetings() // Fetch meetings when the view appears
    }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

struct CalendarViews_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
}
