//
//  TopicView.swift
//  Penpal
//
//  Created by Austin William Tucker on 1/9/25.
//

import SwiftUI

struct TopicView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var meetingViewModel = MeetingViewModel() // Assuming MeetingViewModel
    @StateObject var viewModel: TopicViewModel
    var meetingId: String // Pass the meeting ID from the parent view
    
    @State private var selectedTopics: [String] = [] // Store selected topics
    @State private var selectedSubcategories: [String: [String]] = [:] // Store selected subcategories for each topic
    
    
   
    // Initializer to set up the ViewModels and meeting ID
    init(meetingId: String) {
        _meetingViewModel = StateObject(wrappedValue: MeetingViewModel())
        _viewModel = StateObject(wrappedValue: TopicViewModel(meetingViewModel: meetingViewModel))
    }
    
    var body: some View {
        VStack {
            if meetingViewModel.meeting?.status != "accepted" {
                Text("You can only select topics for accepted meetings.")
                    .foregroundColor(.red)
                    .padding()
            } else {
                // Display the count of selected topics
                Text("\(selectedTopics.count)/2 Topics Selected")
                    .padding()
                    .font(.subheadline)
                    .foregroundColor(selectedTopics.count == 2 ? .green : .black)
                
                // Display the available topics for selection in a List
                List {
                    ForEach(viewModel.topics) { topic in
                        Section(header: Text(topic.name)) {
                            ForEach(topic.subcategories) { subcategory in
                                HStack {
                                    Text(subcategory.name)
                                    Spacer()
                                    if isSelected(topic: topic.name, subcategory: subcategory.name) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    toggleSelection(topic: topic.name, subcategory: subcategory.name)
                                }
                            }
                        }
                    }
                }
                
                // Show selected topics and subcategories
                VStack(alignment: .leading) {
                    Text("Selected Topics:")
                        .font(.headline)
                    // Show a list of selected topics
                    ForEach(selectedTopics, id: \.self) { topic in
                        Text(topic)
                            .padding(.bottom, 2)
                    }
                    
                    Text("Selected Subcategories:")
                        .font(.headline)
                    
                    // Show selected subcategories for each topic
                    ForEach(selectedTopics, id: \.self) { topic in
                        VStack(alignment: .leading) {
                            ForEach(selectedSubcategories[topic] ?? [], id: \.self) { subcategory in
                                Text("- \(subcategory)")
                            }
                        }
                    }
                }
                .padding()
                
                // Button to confirm selections
                Button("Confirm Selections") {
                    confirmSelections()
                }
                .padding()
                .disabled(selectedTopics.isEmpty || selectedSubcategories.isEmpty)
            }
        }
        .onAppear {
            meetingViewModel.fetchMeeting(meetingId: meetingId) // Fetch meeting data
        }
    }
    
    // Function to toggle selection of topics and subcategories
    func toggleSelection(for topic: String, subcategory: String) {
        
        // Check if two topics are already selected
        if selectedTopics.count == 2 && !selectedTopics.contains(topic) {
            // Display an error message
            errorMessage = "2/2 selected. Must remove one selected to add another."
            return
        }
        // If the topic is already selected
        if selectedTopics.contains(topic) {
            // If the subcategory is already selected for this topic, remove it
            if let index = selectedSubcategories[topic]?.firstIndex(of: subcategory) {
                selectedSubcategories[topic]?.remove(at: index)
                // If no subcategories remain for this topic, deselect the topic
                if selectedSubcategories[topic]?.isEmpty == true {
                    selectedTopics.removeAll { $0 == topic }
                }
            } else {
                // Otherwise, add the subcategory to the topic's list of selected subcategories
                selectedSubcategories[topic, default: []].append(subcategory)
            }
        } else {
            // If the topic isn't selected, select it and add the subcategory
            selectedTopics.append(topic)
            selectedSubcategories[topic] = [subcategory]
        }
        
        errorMessage = nil
    }
    
    // Confirm selections and save/update to the backend
    func confirmSelections() {
        // Here you would call a method to save the selections to Firestore or perform other logic
        print("Confirmed Topics: \(selectedTopics)")
        print("Confirmed Subcategories: \(selectedSubcategories)")
        
        // Navigate back to the MeetingView after confirming
        presentationMode.wrappedValue.dismiss()
    }
}
