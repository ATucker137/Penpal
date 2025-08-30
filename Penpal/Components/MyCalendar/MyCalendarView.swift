//
//  CalendarView.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//

/*
 Calendar View Features:
 - Half-screen monthly calendar
 - Scroll/swipe through months
 - Dots on days with scheduled meetings
 - Tap day to show meeting cards
 - Navigate to detailed meeting view via NavigationLink
*/

// TODO: When displaying meetings on a selected date, show the penpal's name.
// Strategy:
// 1. Keep `MeetingModel.participants` as user IDs (do not store names directly).
// 2. In `MyCalendarViewModel`, create a dictionary [userId: PenpalsModel] to map penpal IDs to names.
// 3. Fetch all penpals associated with the current user and populate the dictionary on app launch or calendar view appear.
// 4. When rendering meetings in the view, lookup the participant ID (excluding the logged-in user) and show the penpal's full name.


import SwiftUI

struct MyCalendarView: View {
    @StateObject private var viewModel = MyCalendarViewModel() // ViewModel for loading meetings
    @EnvironmentObject var userSession: UserSession // Shared user state
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTab: Tab

    @State private var selectedDate: Date? = nil
    @State private var currentMonthOffset: Int = 0 // Month index relative to current date

    var body: some View {
        
        VStack(spacing: 16) {
            // MARK: - Header with Back and Add Button
            HStack {
                Button(action: { dismiss() }) {
                    Label("Back", systemImage: "arrow.backward")
                }
                .foregroundColor(.black)

                Spacer()

                Text("My Calendar")
                    .font(.title2)
                    .bold()

                Spacer()

                Button(action: addNewMeeting) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
            .padding()
            // MARK: - Month Navigation Header
            HStack {
                Button(action: { currentMonthOffset -= 1 }) {
                    Image(systemName: "chevron.left")
                }

                Spacer()

                Text(currentMonthDisplay)
                    .font(.headline)
                    .bold()

                Spacer()

                Button(action: { currentMonthOffset += 1 }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)


            // MARK: - Main Content Area
            if let userId = userSession.userId {
                Text("Calendar for User ID: \(userId)")
                    .font(.caption)
                    .foregroundColor(.gray)

                // Month Grid Calendar View
                CalendarMonthGridView(
                    selectedDate: $selectedDate,
                    meetings: viewModel.meetings,
                    monthOffset: currentMonthOffset
                )
                .frame(height: 350)
                .gesture(
                    // MARK: - Allow swipe to change month
                    DragGesture()
                        .onEnded { value in
                            if value.translation.width < -50 {
                                currentMonthOffset += 1  // Swiped left
                            } else if value.translation.width > 50 {
                                currentMonthOffset -= 1  // Swiped right
                            }
                        }
                )
                // MARK: - Meeting Cards for Selected Date
                if let selected = selectedDate {
                    let meetingsOnDay = viewModel.meetings.filter {
                        Calendar.current.isDate($0.startTime, inSameDayAs: selected)
                    }

                    if meetingsOnDay.isEmpty {
                        Text("No meetings on this day.")
                            .foregroundColor(.gray)
                    } else {
                        // MARK: - Display cards for each meeting
                        ForEach(meetingsOnDay) { meeting in
                            NavigationLink(destination: MeetingView(selectedTab: $selectedTab, meetingId: meeting.id)) {
                                Text(meeting.title)
                                    .padding()
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(10)
                            }
                        }
                    }
                }

            } else {
                Text("Please log in to view your calendar.")
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Calendar")
        .onAppear {
            viewModel.fetchAllMeetings()
        }
        
    }
    
    // MARK: - Current Month Display
    private var currentMonthDisplay: String {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .month, value: currentMonthOffset, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    // MARK: - Add a New Meeting (for testing/demo)
    private func addNewMeeting() {
        guard let userId = userSession.userId else { return }

        let newMeeting = MeetingModel(
            id: UUID().uuidString,
            title: "New Event",
            description: "Auto-created",
            startTime: Date(),
            startDate: Date(),
            endTime: Date().addingTimeInterval(3600),
            endDate: Date().addingTimeInterval(3600),
            participants: ["user1", "user2"],
            reminder: true,
            notes: "",
            attendees: [],
            userId: userId
        )

        viewModel.saveMeeting(newMeeting)
    }
}

// MARK: - Monthly Calendar Grid View
struct CalendarMonthGridView: View {
    @Binding var selectedDate: Date?
    let meetings: [MeetingModel]
    let monthOffset: Int

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    // Generates array of all days for the displayed month
    private var calendarDays: [Date] {
        let calendar = Calendar.current
        let today = Date()
        let displayMonth = calendar.date(byAdding: .month, value: monthOffset, to: today)!

        guard let range = calendar.range(of: .day, in: .month, for: displayMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayMonth))
        else { return [] }

        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: firstDay)
        }
    }

    var body: some View {
        HStack {
            // Weekday headers: S M T W T F S
            ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { weekday in
                Text(weekday.prefix(1)) // Optional: limit to one letter like "S"
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.gray)
            }
        }
        // Day grid for the current month
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(calendarDays, id: \.self) { date in
                VStack(spacing: 4) {
                    // Day number
                    Text("\(Calendar.current.component(.day, from: date))")

                    if meetings.contains(where: { Calendar.current.isDate($0.startTime, inSameDayAs: date) }) {
                        Circle()
                            .frame(width: 6, height: 6)
                            .foregroundColor(.blue)
                    }
                    // Highlight selected date
                    if let selected = selectedDate, Calendar.current.isDate(date, inSameDayAs: selected) {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue, lineWidth: 2)
                            .frame(height: 36)
                            .opacity(0.3)
                    }
                }
                .frame(maxWidth: .infinity)
                .onTapGesture {
                    selectedDate = date
                }
            }
        }
    }
}

// MARK: - Date Formatter
extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Preview
struct CalendarViews_Previews: PreviewProvider {
    static var previews: some View {
        MyCalendarView(selectedTab: .constant(.calendar))
            .environmentObject(UserSession())
    }
}
