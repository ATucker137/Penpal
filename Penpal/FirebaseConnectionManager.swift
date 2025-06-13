//
//  FirebaseConnectionManager.swift
//  Penpal
//
//  Created by Austin William Tucker on 4/3/25.
//

import FirebaseDatabase

class FirebaseConnectionMonitor: ObservableObject {
    private let connectedRef = Database.database().reference(withPath: ".info/connected")
    @Published var isConnectedToFirebase: Bool = false

    init() {
        connectedRef.observe(.value) { snapshot in
            if let connected = snapshot.value as? Bool {
                DispatchQueue.main.async {
                    self.isConnectedToFirebase = connected
                }
            }
        }
    }
}
