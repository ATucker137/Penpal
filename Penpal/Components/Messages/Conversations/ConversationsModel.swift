import Foundation

/*
 
 Reason For Struct:
 
 Value Semantics:
 Structs are value types, meaning when you pass them around, you get copies rather than references. This helps avoid unintended side effects and makes them safer for multithreading.

 Performance:
 Structs are stored on the stack, making them faster for read-heavy operations compared to class instances, which are stored on the heap and require reference counting.

*/

// MARK: - ConversationsModel - The Model that will define the list of Conversations
// CodingKeys and the Codable protocol are necessary for interacting with Firestore,
// allowing easy encoding and decoding. Using an enum here is a good practice to map
// the model's properties to Firestore's field names. The enum ensures type safety and flexibility
// in handling any differences between the struct's property names and Firestore's field names.

struct ConversationsModel: Codable, Identifiable {
    
    var id: String        // Unique identifier for each conversation
    var userId: String    // ID of the user who is part of the conversation
    var penpalId: String  // ID of the penpal who is part of the conversation
    var lastMessage: String?  // Optional: The last message in the conversation
    let lastUpdated: Date  // Timestamp of the most recent activity in the conversation

    // MARK: - CodingKeys enum
    enum CodingKeys: String, CodingKey {
        case id, userId, penpalId, lastMessage, lastUpdated
    }
    
    
    // MARK: - From FireStore Data
    func fromFireStoreData(_ data: [String: Any]) -> ConversationsModel {
        guard let id = data["id"] as? String,
              let userId = data["userId"] as? String,
              let penpalId = data["penpalId"] as? String,
              let lastMessage = data["lastMessage"] as? String,
              let lastUpdated = data["lastUpdated"] as? Date
                
        else {
            return nil
        }
        return ConversationsModel(id: id, userId: userId, penpalId: penpalId, lastMessage: lastMessage, lastUpdated: lastUpdated)
    }
    
    // MARK: - To FireStore Data
    
    func toFireStoreData() -> [String: Any] {
        return [
            "id": id,
            "userId": userId,
            "penpalId": penpalId,
            "lastMessage": lastMessage,
            "lastUpdated": lastUpdated
        ]
    }
    
    
}
