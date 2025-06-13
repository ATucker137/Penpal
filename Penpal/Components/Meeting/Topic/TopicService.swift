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


protocol TopicServiceProtocol {
    func fetchTopics(for userId: String, completion: @escaping (Result<[Topics],Error) -> Void)
}

class TopicService: TopicServiceProtocol {
    
    private let db = Firestore.firestore()
    
    // TODO: - Must Add Functions Topic Service
    
    
}
                            
