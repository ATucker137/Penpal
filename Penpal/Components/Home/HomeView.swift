import SwiftUI

// MARK: - Models

struct WeeklyStats {
    let sessions: Int
    let hoursFormatted: String
    let newVocab: Int
}


// MARK: - HomeView

struct HomeView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var messageViewModel: MessagesViewModel
    @EnvironmentObject var penpalViewModel: PenpalsViewModel
    @ObservedObject var homeViewModel: HomeViewModel
    @State private var isShowingCalendar = false
    @Binding var selectedTab: Tab

    init(homeViewModel: HomeViewModel, selectedTab: Binding<Tab>) {
            self._selectedTab = selectedTab
            self.homeViewModel = homeViewModel
        }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // Greeting
                    if let profile = profileViewModel.userProfile {
                        Text("Hello \(profile.firstName) \(profile.lastName)")
                            .font(.title)
                            .fontWeight(.bold)
                    }

                    // Placeholder Weekly Stats
                    WeeklyInsightsView(stats: WeeklyStats(
                        sessions: 4,
                        hoursFormatted: "1h 20m",
                        newVocab: 53)
                    )

                    // Penpal Section
                    Text("Your Penpals")
                        .font(.headline)
                        .padding(.top, 10)

                    ForEach(Array(penpalViewModel.penpalMap.values), id: \.penpalId) { penpal in
                        PenpalCardView(penpal: penpal)
                    }
                    // Button to navigate to Calendar
                    Button(action: {
                        isShowingCalendar = true
                    }) {
                        HStack {
                            Image(systemName: "calendar")
                            Text("My Calendar")
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .padding(.top, 20)
                }
                .padding()
            }
            .navigationBarHidden(true)
            .background(
                NavigationLink(
                    destination: MyCalendarView(selectedTab: $selectedTab),
                    isActive: $isShowingCalendar,
                    label: { EmptyView() }
                )
            )
            .onAppear {
                penpalViewModel.fetchPenpals()
            }
        }
    }
}

// MARK: - Weekly Insights

struct WeeklyInsightsView: View {
    let stats: WeeklyStats

    var body: some View {
        HStack(spacing: 16) {
            InsightItem(title: "Penpal Sessions", value: "\(stats.sessions)")
            InsightItem(title: "Hours Practiced", value: stats.hoursFormatted)
            InsightItem(title: "New Vocabulary", value: "\(stats.newVocab) words")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct InsightItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack {
            Text(value)
                .font(.headline)
                .foregroundColor(.red)
            Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Penpal Card View

struct PenpalCardView: View {
    let penpal: PenpalsModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Profile image (placeholder for now)
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading) {
                    Text("\(penpal.firstName) \(penpal.lastName)")
                        .font(.headline)
                    Text("\(penpal.region) • Status: \(penpal.status.rawValue.capitalized)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "message.fill")
                    .foregroundColor(.blue)
            }
            
            // Placeholder session date — replace with real session data when available
            Text("Upcoming Session")
                .font(.subheadline)
                .foregroundColor(.gray)
            Text("No session scheduled")
                .font(.body)
                .foregroundColor(.red)
            
            // Placeholder points — optional, mock for now
            Text("Points Earned")
                .font(.caption)
                .foregroundColor(.gray)
            Text("0")
                .font(.headline)
            
            // Display hobbies as milestones
            if !penpal.hobbies.isEmpty {
                HStack {
                    ForEach(penpal.hobbies, id: \.id) { hobby in
                        Text("\(hobby.emoji) \(hobby.name)")
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
}



