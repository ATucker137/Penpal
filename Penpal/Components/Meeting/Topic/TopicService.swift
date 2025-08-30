//
//  TopicService.swift
//  Penpal
//
//  Created by Austin William Tucker on 1/9/25.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift


// MARK: - Refactored Protocol
protocol TopicServiceProtocol {
    func fetchTopics(for userId: String) async throws -> [TopicModel]
    func addDiscussionTopic(_ topic: String, to meetingId: String) async throws
    func saveCustomTopic(_ topic: TopicModel, for userId: String) async throws
    func updateSubcategories(for topicName: String, newSubcategories: [String], meetingId: String) async throws
    func deleteTopic(_ topic: TopicModel, for userId: String) async throws
}
class TopicService: TopicServiceProtocol {
    
    private let db = Firestore.firestore()
    private let category = "Topic Service"
    
    // TODO: - Must Add Functions Topic Service
    
    // MARK: - Fetch Topics for a User (optional, based on how you want to structure it)
    func fetchTopics(for userId: String) async throws -> [TopicModel] {
            LoggerService.shared.log(.info, "Fetching topics for userId: \(userId)", category: self.category)
            
            do {
                let snapshot = try await db.collection("users").document(userId).collection("topics").getDocuments()
                
                guard !snapshot.documents.isEmpty else {
                    LoggerService.shared.log(.warning, "No topic documents found for userId: \(userId)", category: self.category)
                    return []
                }
                
                let topics: [TopicModel] = try snapshot.documents.compactMap { doc in
                    return try doc.data(as: TopicModel.self)
                }
                
                LoggerService.shared.log(.info, "Successfully fetched \(topics.count) topics", category: self.category)
                return topics
                
            } catch {
                LoggerService.shared.log(.error, "Failed to fetch topics: \(error.localizedDescription)", category: self.category)
                throw error
            }
        }

    
    // MARK: - Add Discussion Topic to a Meeting
    func addDiscussionTopic(_ topic: String, to meetingId: String) async throws {
        LoggerService.shared.log(.info, "Attempting to add topic '\(topic)' to meetingId: \(meetingId)", category: self.category)
        
        let meetingRef = db.collection("meetings").document(meetingId)
        
        do {
            try await meetingRef.updateData([
                "discussionTopics.\(topic)": FieldValue.arrayUnion([]) // initializes with empty subcategory list
            ])
            LoggerService.shared.log(.info, "Successfully added topic '\(topic)' to meetingId: \(meetingId)", category: self.category)
        } catch {
            LoggerService.shared.log(.error, "Failed to add topic '\(topic)' to meetingId: \(meetingId). Error: \(error.localizedDescription)", category: self.category)
            throw error
        }
    }


    // MARK: - Save a Custom Topic (Optional - for personalization)
    func saveCustomTopic(_ topic: TopicModel, for userId: String) async throws {
        LoggerService.shared.log(.info, "Starting to save custom topic '\(topic.name)' for userId: \(userId)", category: self.category)
        
        let topicData: [String: Any] = [
            "id": topic.id,
            "name": topic.name,
            "subcategories": topic.subcategories.map { ["id": $0.id, "name": $0.name] },
            "isSynced": topic.isSynced
        ]
        
        do {
            try await db.collection("users")
                .document(userId)
                .collection("topics")
                .document(topic.id)
                .setData(topicData)
            
            LoggerService.shared.log(.info, "Successfully saved custom topic '\(topic.name)' with id '\(topic.id)' for userId: \(userId)", category: self.category)
        } catch {
            LoggerService.shared.log(.error, "Failed to save custom topic '\(topic.name)' for userId: \(userId). Error: \(error.localizedDescription)", category: self.category)
            throw error
        }
    }
    
    // MARK: - Update Subcategories for a Specific Topic in a Meeting
    /// Updates the subcategories array for a specific topic in a meeting document.
    /// - Parameters:
    ///   - topicName: The topic name whose subcategories you want to update.
    ///   - newSubcategories: Array of subcategory strings to set for the topic.
    ///   - meetingId: The ID of the meeting document.
    /// - Throws: Propagates any error from Firestore update.
    func updateSubcategories(for topicName: String,
                             newSubcategories: [String],
                             meetingId: String) async throws {
        LoggerService.shared.log(.info, "Attempting to update subcategories for topic '\(topicName)' in meetingId: \(meetingId)", category: category)
        
        let meetingRef = db.collection("meetings").document(meetingId)
        let fieldKey = "discussionTopics.\(topicName)"
        
        do {
            LoggerService.shared.log(.debug, "Updating field '\(fieldKey)' with new subcategories: \(newSubcategories)", category: category)
            try await meetingRef.updateData([
                fieldKey: newSubcategories
            ])
            LoggerService.shared.log(.info, "Successfully updated subcategories for topic '\(topicName)' in meetingId: \(meetingId)", category: category)
        } catch {
            LoggerService.shared.log(.error, "Error updating subcategories for topic '\(topicName)' in meetingId: \(meetingId): \(error.localizedDescription)", category: category)
            throw error
        }
    }
    
    // MARK: - Delete a Custom Topic
    func deleteTopic(_ topic: TopicModel, for userId: String) async throws {
        LoggerService.shared.log(.info, "Attempting to delete topic '\(topic.name)' for userId: \(userId)", category: self.category)
        
        do {
            try await db.collection("users")
                .document(userId)
                .collection("topics")
                .document(topic.id)
                .delete()
            
            LoggerService.shared.log(.info, "Successfully deleted topic '\(topic.name)' with id '\(topic.id)' for userId: \(userId)", category: self.category)
        } catch {
            LoggerService.shared.log(.error, "Failed to delete topic '\(topic.name)' for userId: \(userId). Error: \(error.localizedDescription)", category: self.category)
            throw error
        }
    }
}
                            
