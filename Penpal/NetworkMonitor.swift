//
//  NetworkMonitor.swift
//  Penpal
//
//  Created by Austin William Tucker on 4/3/25.
//
import Network
import FirebaseFirestore

/// Singleton class to monitor network connectivity and update Firebase status.
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor() // Shared instance
    
    private let monitor = NWPathMonitor() // Monitors network status
    private let queue = DispatchQueue.global(qos: .background) // Runs monitoring in background
    
    @Published var isConnected: Bool = true // Tracks internet connectivity
    
    private init() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                let newStatus = path.status == .satisfied
                if self.isConnected != newStatus {
                    self.isConnected = newStatus
                    self.updateUserStatus(isOnline: newStatus) //  Update Firestore!
                }
            }
        }
        monitor.start(queue: queue)
    }

    /// Updates the user's `isOnline` status in Firestore.
    private func updateUserStatus(isOnline: Bool) {
        guard let userId = FirebaseAuth.Auth.auth().currentUser?.uid else { return }

        let userRef = Firestore.firestore().collection("users").document(userId)
        userRef.updateData(["isOnline": isOnline, "lastSeen": isOnline ? nil : Timestamp()]) { error in
            if let error = error {
                print("❌ Failed to update user status: \(error.localizedDescription)")
            }
        }
    }
}

