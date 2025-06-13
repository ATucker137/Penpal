//
//  FirestoreService.swift
//  Penpal
//
//  Created by Austin William Tucker on 4/8/25.
//

import Foundation
import FirebaseFirestore

class FirestoreService {
    private let db = Firestore.firestore()

    func updateOnlineStatus(userId: String, isOnline: Bool) {
        db.collection("users").document(userId).updateData([
            "isOnline": isOnline,
            "lastActive": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print("Error updating status: \(error)")
            }
        }
    }
}
