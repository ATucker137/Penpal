//
//  MainTabView.swift
//  Penpal
//
//  Created by Austin William Tucker on 1/20/25.
//

import SwiftUI

// TODO: - The Image Names like house.fill can be reached here: https://developer.apple.com/sf-symbols/
// TODO: - Pass in the binding into each
class MainTabView: View {
    
    @State private var selectedTab = Tab .home
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(Tab.home)
            PenpalsView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Penpals", systemImage: "person.2.fill")
                }
                .tag(Tab.penpals)
            MessagesView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Messages",systemImage: "message.fill")
                }
                .tag(Tab.messages)
            StudyView(selectedTab: $selectedTab)
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
    case home, penpals,messages, study, profile
}
