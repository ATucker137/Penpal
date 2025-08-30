//
//  MainTabView.swift
//  Penpal
//
//  Created by Austin William Tucker on 1/20/25.
//
/**
 MainTabView.swift

 This is the **Parent View** of the Penpal app which manages the primary navigation structure using a **TabView**. It serves as the root container that holds five main sections of the app:
 
 1. **Home** - User’s feed or dashboard.
 2. **Penpals** - List of potential or confirmed Penpal matches.
 3. **Messages** - User’s conversations and message threads.
 4. **Study** - Vocabulary sheets and study tools.
 5. **Profile** - User profile and settings.
 
 Shared state like the currently selected tab (`selectedTab`) and navigation helpers (e.g., `lastOpenedMessageId` for deep-linking into a message) are stored here and passed down as Bindings to child views for inter-tab communication and navigation actions.

 This view should be launched as the root view when the app starts.

**/
 
import SwiftUI

// TODO: - The Image Names like house.fill can be reached here: https://developer.apple.com/sf-symbols/
// TODO: - Pass in the binding into each
struct MainTabView: View {
    
    @State private var selectedTab = Tab.home
    @State private var lastOpenedMessageId: String? = nil // Start empty
    @StateObject private var homeVM = HomeViewModel()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(homeViewModel: homeVM, selectedTab: $selectedTab)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(Tab.home)
            PenpalView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Penpals", systemImage: "person.2.fill")
                }
                .tag(Tab.penpals)
            // MARK: - TODO Should First Go into the Conversations Tab But if ID like for it to go into the exact message if the user clicked on one an dnavigate sback to the app
            MessagesWrapperView(selectedTab: $selectedTab, lastOpenedMessageId: $lastOpenedMessageId)
                .tabItem {
                    Label("Messages",systemImage: "message.fill")
                }
                .tag(Tab.messages)
            VocabSheetView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Study",systemImage: "book.fill")
                }
                .tag(Tab.study)
            ProfileView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Profile",systemImage: "person.crop.circle.fill")
                }
                .tag(Tab.profile)
        }
        .onAppear() {
            selectedTab = .home
        }
    }
}


enum Tab {
    case home, penpals, messages, study, profile
}
