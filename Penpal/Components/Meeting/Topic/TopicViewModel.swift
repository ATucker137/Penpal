//
//  TopicViewModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 1/9/25.
//



import Foundation

class TopicViewModel : ObservableObject {
    
    // MARK: - Published Properties
    @Published var meeting: MeetingModel?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var newTopic: String = ""
    
    // MARK: - Declaring Topics And Topics And Subcategories
    @Published var topics: [Topic] = [
        Topic(id: UUID().uuidString, name: "Travel", subcategories: [
            Subcategory(id: UUID().uuidString, name: "Practice Conversation"),
            Subcategory(id: UUID().uuidString, name: "Vocabulary"),
            Subcategory(id: UUID().uuidString, name: "Practice Roleplay"),
            Subcategory(id: UUID().uuidString, name: "Common Phrases")
        ]),
        Topic(id: UUID().uuidString, name: "Sports", subcategories: [
                Subcategory(id: UUID().uuidString, name: "Practice Conversation"),
                Subcategory(id: UUID().uuidString, name: "Vocabulary"),
                Subcategory(id: UUID().uuidString, name: "Practice Roleplay"),
                Subcategory(id: UUID().uuidString, name: "Common Phrases")
        ]),
        Topic(id: UUID().uuidString, name: "Culture", subcategories: [
            Subcategory(id: UUID().uuidString, name: "Practice Conversation"),
            Subcategory(id: UUID().uuidString, name: "Vocabulary"),
            Subcategory(id: UUID().uuidString, name: "Practice Roleplay"),
            Subcategory(id: UUID().uuidString, name: "Common Phrases")
        ]),
        Topic(id: UUID().uuidString, name: "Culture", subcategories: [
            Subcategory(id: UUID().uuidString, name: "Practice Conversation"),
            Subcategory(id: UUID().uuidString, name: "Vocabulary"),
            Subcategory(id: UUID().uuidString, name: "Practice Roleplay"),
            Subcategory(id: UUID().uuidString, name: "Common Phrases")
        ]),
        Topic(id: UUID().uuidString, name: "Food", subcategories: [
            Subcategory(id: UUID().uuidString, name: "Practice Conversation"),
            Subcategory(id: UUID().uuidString, name: "Vocabulary"),
            Subcategory(id: UUID().uuidString, name: "Practice Roleplay"),
            Subcategory(id: UUID().uuidString, name: "Common Phrases")
        ]),
        Topic(id: UUID().uuidString, name: "Movies", subcategories: [
            Subcategory(id: UUID().uuidString, name: "Practice Conversation"),
            Subcategory(id: UUID().uuidString, name: "Vocabulary"),
            Subcategory(id: UUID().uuidString, name: "Practice Roleplay"),
            Subcategory(id: UUID().uuidString, name: "Common Phrases")
        ]),
        Topic(id: UUID().uuidString, name: "Art", subcategories: [
            Subcategory(id: UUID().uuidString, name: "Practice Conversation"),
            Subcategory(id: UUID().uuidString, name: "Vocabulary"),
            Subcategory(id: UUID().uuidString, name: "Practice Roleplay"),
            Subcategory(id: UUID().uuidString, name: "Common Phrases")
        ]),
        Topic(id: UUID().uuidString, name: "Daily Life", subcategories: [
            Subcategory(id: UUID().uuidString, name: "Practice Conversation"),
            Subcategory(id: UUID().uuidString, name: "Vocabulary"),
            Subcategory(id: UUID().uuidString, name: "Practice Roleplay"),
            Subcategory(id: UUID().uuidString, name: "Common Phrases")
        ]),
        Topic(id: UUID().uuidString, name: "Health And Wellness", subcategories: [
            Subcategory(id: UUID().uuidString, name: "Practice Conversation"),
            Subcategory(id: UUID().uuidString, name: "Vocabulary"),
            Subcategory(id: UUID().uuidString, name: "Practice Roleplay"),
            Subcategory(id: UUID().uuidString, name: "Common Phrases")
        ]),
    ]
    
    
    // MARK: - Properties
    private var meeetingService = MeetingService()
    private var meetingViewModel: MeetingViewModel
    
    //MARK: - Fetch The Meeting Data
    // Initialize with the existing MeetingViewModel
    init(meetingViewModel: MeetingViewModel) {
        self.meetingViewModel = meetingViewModel
    }
    
    // MARK: - Add Discussion Topic to Meeting
    func addDiscussionTopic() {
        guard let meetingId = meetingViewModel.meeting?.id else {
            errorMessage = "Meeting ID is missing."
            return
        }
        
        // Call the MeetingService to add the new topic to Firestore
        meetingService.addDiscussionTopicsToMeeting(discussionTopic: newTopic, meetingId: meetingId)
        
        // Clear the new topic field after adding
        newTopic = ""
        
        // Re-fetch the meeting to get updated topics (using the MeetingViewModel's fetchMeeting)
        meetingViewModel.fetchMeeting(meetingId: meetingId)
    }
    
}
