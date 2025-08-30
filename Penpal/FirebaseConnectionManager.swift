//
//  FirebaseConnectionManager.swift
//  Penpal
//
//  Created by Austin William Tucker on 4/3/25.
//

import FirebaseDatabase
import Combine

/// Monitors the connection status to Firebase Realtime Database.
/// - Note: This monitors only Realtime Database connectivity, not Firestore.
class FirebaseConnectionMonitor: ObservableObject {
    private let connectedRef = Database.database().reference(withPath: ".info/connected")
    
    /// Published property indicating if the client is connected to Firebase Realtime Database.
    @Published var isConnectedToFirebase: Bool = false
    
    /// Combine publisher for connection status updates.
    let connectionStatusPublisher = CurrentValueSubject<Bool, Never>(false)
    
    private var handle: DatabaseHandle?
    
    /// Optional callback closure for status changes (for non-SwiftUI consumers).
    var onStatusChange: ((Bool) -> Void)?
    
    init() {
        observeConnection()
    }
    
    deinit {
        cleanupObserver()
    }
    
    /// Sets up the observer on `.info/connected` Firebase Realtime Database path.
    private func observeConnection() {
        handle = connectedRef.observe(.value) { [weak self] snapshot in
            guard let self = self else { return }
            
            if let connected = snapshot.value as? Bool {
                DispatchQueue.main.async {
                    self.isConnectedToFirebase = connected
                    self.connectionStatusPublisher.send(connected)
                    self.onStatusChange?(connected)
                }
            } else {
                // Handle unexpected data (e.g., null or wrong type)
                DispatchQueue.main.async {
                    self.isConnectedToFirebase = false
                    self.connectionStatusPublisher.send(false)
                    self.onStatusChange?(false)
                }
            }
        }
    }
    
    /// Removes Firebase observer to prevent memory leaks.
    func cleanupObserver() {
        if let handle = handle {
            connectedRef.removeObserver(withHandle: handle)
        }
    }
}
