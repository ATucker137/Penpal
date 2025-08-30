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
                LoggerService.shared.log(.error, "Error updating online status for user \(userId): \(error.localizedDescription)", category: LogCategory.firestoreProfile)
            } else {
                LoggerService.shared.log(.info, "Successfully updated online status for user \(userId) to \(isOnline)", category: LogCategory.firestoreProfile)
            }
        }
    }
}
