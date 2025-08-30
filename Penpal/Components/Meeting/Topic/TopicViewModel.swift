//
//  TopicViewModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 1/9/25.
//



import Foundation
import FirebaseFirestore

class TopicViewModel : ObservableObject {
    
    // MARK: - Published Properties
    @Published var meeting: MeetingModel?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var newTopic: String = ""
    
    private let category = "Topic Viewmodel"
    
    // MARK: - Declaring Topics And Topics And Subcategories
    @Published var topics: [TopicModel] = [
        TopicModel(id: UUID().uuidString, name: "Travel", subcategories: [
            Subcategory(id: UUID().uuidString, name: "Practice Conversation"),
            Subcategory(id: UUID().uuidString, name: "Vocabulary"),
            Subcategory(id: UUID().uuidString, name: "Practice Roleplay"),
            Subcategory(id: UUID().uuidString, name: "Common Phrases")
        ]),
        TopicModel(id: UUID().uuidString, name: "Sports", subcategories: [
                Subcategory(id: UUID().uuidString, name: "Practice Conversation"),
                Subcategory(id: UUID().uuidString, name: "Vocabulary"),
                Subcategory(id: UUID().uuidString, name: "Practice Roleplay"),
                Subcategory(id: UUID().uuidString, name: "Common Phrases")
        ]),
        TopicModel(id: UUID().uuidString, name: "Culture", subcategories: [
            Subcategory(id: UUID().uuidString, name: "Practice Conversation"),
            Subcategory(id: UUID().uuidString, name: "Vocabulary"),
            Subcategory(id: UUID().uuidString, name: "Practice Roleplay"),
            Subcategory(id: UUID().uuidString, name: "Common Phrases")
        ]),
        TopicModel(id: UUID().uuidString, name: "Food", subcategories: [
            Subcategory(id: UUID().uuidString, name: "Practice Conversation"),
            Subcategory(id: UUID().uuidString, name: "Vocabulary"),
            Subcategory(id: UUID().uuidString, name: "Practice Roleplay"),
            Subcategory(id: UUID().uuidString, name: "Common Phrases")
        ]),
        TopicModel(id: UUID().uuidString, name: "Movies", subcategories: [
            Subcategory(id: UUID().uuidString, name: "Practice Conversation"),
            Subcategory(id: UUID().uuidString, name: "Vocabulary"),
            Subcategory(id: UUID().uuidString, name: "Practice Roleplay"),
            Subcategory(id: UUID().uuidString, name: "Common Phrases")
        ]),
        TopicModel(id: UUID().uuidString, name: "Art", subcategories: [
            Subcategory(id: UUID().uuidString, name: "Practice Conversation"),
            Subcategory(id: UUID().uuidString, name: "Vocabulary"),
            Subcategory(id: UUID().uuidString, name: "Practice Roleplay"),
            Subcategory(id: UUID().uuidString, name: "Common Phrases")
        ]),
        TopicModel(id: UUID().uuidString, name: "Daily Life", subcategories: [
            Subcategory(id: UUID().uuidString, name: "Practice Conversation"),
            Subcategory(id: UUID().uuidString, name: "Vocabulary"),
            Subcategory(id: UUID().uuidString, name: "Practice Roleplay"),
            Subcategory(id: UUID().uuidString, name: "Common Phrases")
        ]),
        TopicModel(id: UUID().uuidString, name: "Health And Wellness", subcategories: [
            Subcategory(id: UUID().uuidString, name: "Practice Conversation"),
            Subcategory(id: UUID().uuidString, name: "Vocabulary"),
            Subcategory(id: UUID().uuidString, name: "Practice Roleplay"),
            Subcategory(id: UUID().uuidString, name: "Common Phrases")
        ]),
    ]
    
    
    // MARK: - Properties
    private var meetingService = MeetingService()
    private var meetingViewModel: MeetingViewModel
    
    //MARK: - Fetch The Meeting Data
    // Initialize with the existing MeetingViewModel and Meeting Service
    init(meetingViewModel: MeetingViewModel, meetingService: MeetingService = MeetingService()) {
        self.meetingViewModel = meetingViewModel
        self.meetingService = meetingService
    }
    // MARK: - Add Discussion Topic to Meeting
    func addDiscussionTopic() async {
        LoggerService.shared.log(.info, "Starting addDiscussionTopic process", category: self.category)
        
        guard let meetingId = meetingViewModel.meeting?.id else {
            errorMessage = "Meeting ID is missing."
            LoggerService.shared.log(.error, "Meeting ID is missing when attempting to add discussion topic", category: self.category)
            return
        }
        
        LoggerService.shared.log(.info, "Attempting to add new topic '\(newTopic)' to meetingId: \(meetingId)", category: self.category)
        
        do {
            // Call the MeetingService to add the new topic to Firestore
            try await meetingService.addDiscussionTopicsToMeeting(discussionTopic: newTopic, meetingId: meetingId)
            LoggerService.shared.log(.info, "Successfully added topic '\(newTopic)' to meetingId: \(meetingId)", category: self.category)
            
            // Clear the new topic field after adding
            newTopic = ""
            LoggerService.shared.log(.debug, "Cleared newTopic field after successful addition", category: self.category)
            
            // Re-fetch the meeting to get updated topics (using the MeetingViewModel's fetchMeeting)
            LoggerService.shared.log(.info, "Fetching updated meeting for meetingId: \(meetingId)", category: self.category)
            await meetingViewModel.fetchMeeting(meetingId: meetingId)
            LoggerService.shared.log(.info, "Finished fetching updated meeting for meetingId: \(meetingId)", category: self.category)
            
        } catch {
            errorMessage = error.localizedDescription
            LoggerService.shared.log(.error, "Failed to add topic '\(newTopic)': \(error.localizedDescription)", category: self.category)
        }
        
        LoggerService.shared.log(.info, "Ending addDiscussionTopic process", category: self.category)
    }
    
    // MARK: - Fetching Topics
    @MainActor
    func fetchTopics(for userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedTopics = try await TopicService().fetchTopics(for: userId)
            self.topics = fetchedTopics
            LoggerService.shared.log(.info, "Fetched \(fetchedTopics.count) topics for userId: \(userId)", category: self.category)
        } catch {
            self.errorMessage = error.localizedDescription
            LoggerService.shared.log(.error, "Failed to fetch topics: \(error.localizedDescription)", category: self.category)
        }
        
        isLoading = false
    }
    
    // MARK: - Update Subcategories for a Specific Topic in a Meeting
    /// Updates the subcategories for a given topic in the specified meeting.
    /// - Parameters:
    ///   - topicName: The name of the topic to update (e.g., "Travel").
    ///   - newSubcategories: An array of subcategory names to replace the existing list.
    ///   - meetingId: The ID of the meeting to update.
    /// - Throws: An error if the Firestore update fails.
    func updateSubcategories(for topicName: String,
                             newSubcategories: [String],
                             in meetingId: String) async throws {
        LoggerService.shared.log(.info, "Starting update of subcategories for topic '\(topicName)' in meetingId: \(meetingId)", category: category)
        
        let meetingRef = db.collection("meetings").document(meetingId)
        
        // Prepare the Firestore field path using topic name
        let fieldKey = "discussionTopics.\(topicName)"
        
        do {
            LoggerService.shared.log(.debug, "Updating Firestore field '\(fieldKey)' with subcategories: \(newSubcategories)", category: category)
            
            // Update the subcategories array for the specified topic
            try await meetingRef.updateData([
                fieldKey: newSubcategories
            ])
            
            LoggerService.shared.log(.info, "Successfully updated subcategories for topic '\(topicName)' in meetingId: \(meetingId)", category: category)
            
        } catch {
            LoggerService.shared.log(.error, "Failed to update subcategories for topic '\(topicName)' in meetingId: \(meetingId). Error: \(error.localizedDescription)", category: category)
            throw error
        }
    }


    
    
    // MARK: - Save Custom Topic
    @MainActor
    func saveCustomTopic(_ topic: TopicModel, for userId: String) async {
        do {
            try await topicService.saveCustomTopic(topic, for: userId)
            LoggerService.shared.log(.info, "Saved custom topic '\(topic.name)' for userId: \(userId)", category: category)
        } catch {
            errorMessage = error.localizedDescription
            LoggerService.shared.log(.error, "Failed to save custom topic '\(topic.name)': \(error.localizedDescription)", category: category)
        }
    }
}
