//
//  HomeView.swift
//  Penpal
//
//  Created by Austin William Tucker on 12/14/24.
//
//


struct HomeView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var quizViewModel: QuizViewModel
    @EnvironmentObject var messageViewModel: MessagesViewModel
    
    @ObservedObject var homeViewModel: HomeViewModel // Use @ObservedObject here instead of @StateObject
    @Binding var selectedTab: Tab
    
    init(profileViewModel: ProfileViewModel, quizViewModel: QuizViewModel, messageViewModel: MessageViewModel, homeViewModel: HomeViewModel) {
        self.profileViewModel = profileViewModel
        self.quizViewModel = quizViewModel
        self.messageViewModel = messageViewModel
        self.homeViewModel = homeViewModel
    }
    var body: some View {
        VStack {
            if ( homeViewModel.isLoading) {
                ProgressView("Loading")
            } else {
                // Use HomeViewModel's published properties to display data
                if let userProfile = homeViewModel.userProfile {
                    Text("Welcome, \(userProfile.name)!")
                }

                if !homeViewModel.suggestedQuizzes.isEmpty {
                    Text("Suggested Quizzes: \(homeViewModel.suggestedQuizzes.count)")
                }

                if !homeViewModel.recentMessages.isEmpty {
                    Text("Recent Messages: \(homeViewModel.recentMessages.count)")
                }
            }
        }
        .onAppear {
            homeViewModel.fetchHomeData()
        }
    }
    
}

struct HomeViews_Previews: PreviewProvider {
    /*
     TODO: - Preview Not Currently Working
    static var previews: some View {
        //HomeView(profileViewModel: <#T##ProfileViewModel#>, quizViewModel: <#T##_#>, messageViewModel: <#T##_#>, homeViewModel: <#T##HomeViewModel#>)
    }
     */
}
