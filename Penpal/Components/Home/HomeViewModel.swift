//
//  HomeViewModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 12/14/24.
//

// CalendarViewModel Brought In As Home
// MessagesViewModel Brought In As Home
// PenpalViewModel Brought In As Home
// CalendarViewModel Brought In As Home
// ProfileViewModel Brought Into Home


// MARK: - HomeViewModel - ViewModel Class within the MVVM Structure
class HomeViewModel: ObservableObject {
    
    // MARK: - Properties of HomeView Model
    @Published var profile: Profile
    @Published var quizzes: [Quiz] = []
    @Published var recentMessages: [Messages] = []
    @Published var isLoading: Bool = false
    
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
    
    //MARK: - Posible Functions Needed
    
    
    
    
    
    // MARK: - Filter the profiles you want to see in home tab
    func filterPenpalsInHome{
        
    }
    
    
    //MARK: - Most of these function will be common with all of their respective tabs
    
    
    //MARK: - Click Calendar Button
    func clickCalendarButton(){
        
    }
    
    // MARK: - This should go to the specific user though as well
    func clickSendMeetingInvite(){
        
    }
    
    // MARK: - This should go to the specific user though as well
    func clickConversationWithPenpalButton(){
        
    }
    
    // MARK: - Click the Penpal Tab, will navigate to Penpal Tab
    func clickPenpalTab() {
        
    }
    // MARK: - Click the Message Tab, will navigate to Message Tab
    func clickMessageTab() {
        
    }
    
    // MARK: - Click the Study Tab, will navigate to Study Tab
    func clickStudyTab() {
        
    }
    
    // MARK: - Click the Profile Tab, will navigate to Profile Tab
    func clickProfileTab() {
        
    }
}
