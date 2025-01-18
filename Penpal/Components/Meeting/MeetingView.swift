//
//  MeetingView.swift
//  Penpal
//
//  Created by Austin William Tucker on 12/28/24.
//

// When On the CalendarView and clicking onto a Meeting, the user will be taken here to the details of the Meeting
 

/*
 
 
 Things That Should Be  included Within MeetingView
 
 The top of the screen should be the time and date of the meeting
 
 And then under have who its with
 
 Then also a button could be present for contact that navigates to messages
 
 Havbe button under for rescheduling??
 
 
 MeetingLink
 
 
 Functionality for generating a Zoom Link? -- Could Tell The User to just copy it from Google Meet Or Zoom. This or having a button for generating  a zoom link
 
 Ability to edit the Meeting
 

 
 */

import SwiftUI

struct MeetingView: View {
    @StateObject private var viewModel = MeetingViewModel()
    @EnvironmentObject var userSession: UserSession
    //Acts as a back button
    @Environment(\.dismiss) private var dismiss // Dismiss the current view
    let meetingId: String
    
    var body: some View {
        VStack {
            
            Text("Meeting Overview")
            Text(viewModel.meeting.title)
                .font(.largeTitle)
                .bold()
            Text(viewModel.meeting?.datetime)
            
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

