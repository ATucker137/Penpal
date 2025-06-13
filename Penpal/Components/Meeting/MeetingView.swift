//
//  MeetingView.swift
//  Penpal
//
//  Created by Austin William Tucker on 12/28/24.
//

import SwiftUI

struct MeetingView: View {
    @StateObject private var viewModel = MeetingViewModel()
    @EnvironmentObject var userSession: UserSession
    //Acts as a back button
    @Environment(\.dismiss) private var dismiss // Dismiss the current view
    @Binding var selectedTab: Tab
    @State private var showTopicView: Bool = false // State to trigger navigation
    @State private var showScheduleView: Bool = false // State to show ScheduleMeetingTimeView
    @State private var rescheduledDate: Date = Date() // Store the rescheduled date
    @State private var meetingId: String // This will come from the initializer

    
    var body: some View {
        VStack {
            
            Text("Meeting Overview")
            Text(viewModel.meeting?.title ?? "No Title")
                .font(.largeTitle)
                .bold()
            Text(viewModel.meeting?.datetime ?? "No Date/Time")
            
            // Button for navigating to TopicView
            NavigationLink(destination: TopicView(meetingId: meetingId), isActive: $showTopicView) {
                Button("Select Topics") {
                    showTopicView.toggle() // Trigger navigation to TopicView
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            // NavigationLink for ScheduleMeetingTimeView
            NavigationLink(destination: ScheduleMeetingTimeView(isPresented: $showScheduleView, rescheduledDate: $rescheduledDate, meetingId: meetingId)) {
                Button("Reschedule") {
                    showScheduleView.toggle() // Trigger the NavigationLink
                }
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)
            }

            // Example buttons for other functionalities (e.g., contact, reschedule, etc.)
            Button("Contact") {
                // Logic for contacting (e.g., navigate to messages)
            }
            .padding()
            
        }
        .padding()
        .navigationTitle("Meeting Details")
        .toolbar {
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
        .onAppear  {
            viewModel.fetchMeetingDetails(meetingId: meetingId)
        }
        .sheet(isPresented: $showScheduleView) {
                    ScheduleMeetingTimeView(isPresented: $showScheduleView, rescheduledDate: $rescheduledDate, meetingId: meetingId)
                }
    }
    
    extension DateFormatter {
        static let shortDate: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter
        }
    }
    
    struct MeetingView_Previews: PreviewProvider {
        static var previews: some View {
            return MeetingView(userSession: <#T##UserSession#>, meetingId: <#T##String#>)
        }
    }
}

