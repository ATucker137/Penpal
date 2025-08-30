//
//  HomeViewModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 12/14/24.
//

// CalendarViewModel Brought In As Home
// MessagesViewModel Brought In As Home
// PenpalViewModel Brought In As Home
// ProfileViewModel Brought Into Home


// MARK: - HomeViewModel - ViewModel Class within the MVVM Structure
class HomeViewModel: ObservableObject {
    
    // MARK: - Properties of HomeView Model
    @Published var profile: Profile
    @Published var quizzes: [Quiz] = []
    @Published var recentMessages: [Messages] = []
    @Published var calendarViewModel: MyCalendarViewModel
    @Published var isLoading: Bool = false
    
    
    // MARK: - Initializer
        init(profile: Profile, calendarViewModel: MyCalendarViewModel = MyCalendarViewModel()) {
            self.profile = profile
            self.calendarViewModel = calendarViewModel // Initialize MyCalendarViewModel
        }
    
    // Look More into this
    // MARK: - Fetch All Home Data Needed
    func fetchHomeData() {
            // If necessary, you can trigger fetches from other view models.
            isLoading = true
            profileViewModel.fetchUserProfile()
            quizViewModel.fetchSuggestedQuizzes()
            messageViewModel.fetchRecentMessages()
            isLoading = false
        }
    
    //MARK: - Possible Functions Needed
    
    
    
    
    
    // MARK: - Filter the Penpals you want to see in home tab
    func filterPenpalsInHome(criteria: [String]) -> [PenpalsModel] {
        
        // TODO: - Create 'fetchAllPenpals'
        let allUsersPenpals: [PenpalsModel] = fetchAllPenpals()
        
        // What could criterie be for filtering? new? have meetin gscheduled?
        
        // Based off the criteria, pull
        /*
        let filteredPenpals = allUsersPenpals.filter {
            penpal in
            
        }
         */
        
    }
    
    //MARK: - Possible Functions That Might Be Needed In Future
    
    // Some Kind Of New Notifications Thing
    

    

}
