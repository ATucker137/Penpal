//
//  PenpalsView.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//

import SwiftUI

// MARK: - Main Penpal View
// This view displays a swipeable list of potential penpals with filters and action buttons.
struct PenpalsView: View {
    @StateObject private var viewModel = PenpalViewModel()

    // MARK: - Filtering State Variables
    @State private var selectedHobby: String = "All"
    @State private var selectedProficiency: String = "All"
    @State private var selectedRegion: String = "All"
    // TODO: - Also needs the selectedTab

    var body: some View {
        VStack {
            // MARK: - Filter Bar
            HStack {
                // Hobbies Filter
                Picker("Hobby", selection: $selectedHobby) {
                    Text("All").tag("All")
                    ForEach(viewModel.allHobbies, id: \.self) { hobby in
                        Text(hobby).tag(hobby)
                    }
                }
                .pickerStyle(MenuPickerStyle())

                // Proficiency Filter
                Picker("Proficiency", selection: $selectedProficiency) {
                    Text("All").tag("All")
                    ForEach(viewModel.allProficiencies, id: \.self) { level in
                        Text(level).tag(level)
                    }
                }
                .pickerStyle(MenuPickerStyle())

                // Region Filter
                Picker("Region", selection: $selectedRegion) {
                    Text("All").tag("All")
                    ForEach(viewModel.allRegions, id: \.self) { region in
                        Text(region).tag(region)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            .padding()
            
            // MARK: - Swipeable Penpal Cards
            TabView {
                ForEach(viewModel.filteredPenpals(hobby: selectedHobby, proficiency: selectedProficiency, region: selectedRegion)) { penpal in
                    PenpalCard(
                        penpal: penpal,
                        onReject: { viewModel.rejectPenpal(penpal) },
                        onAccept: { viewModel.acceptPenpal(penpal) }
                    )
                    .padding()
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always)) // Swipe through profiles
        }
        .onAppear {
            viewModel.fetchPenpals() // Load potential penpals when the view appears
        }
    }
}
