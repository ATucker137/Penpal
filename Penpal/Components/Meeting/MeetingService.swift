//
//  MeetingService.swift
//  Penpal
//
//  Created by Austin William Tucker on 12/29/24.
//

// Within this file should outline the connection with Firebase


import FirebaseFirestore
import Firebase
import Firebase

// TODO: Batch Operation will probably be needed for updating a user schedule. Would also probably need the user to be able to acccept the meeting as well



class MeetingService {
    
    private let db = Firebase.firestore()
    
    private let collectionName = "meeting"
    
    
    // MARK: - Create Meeting Through Firestore
    func createMeeting(meeting: Meeting, completion: @escaping (Result<Void,Error) -> Void) {
        do {
            // Create the meeting document from Firestore
            try db.collection(collectionName).document(meeting.id).setData(from: meeting) {
                error in
                if let error = error {
                    completion(.failure(error))
                }
                else {
                    completion(.success(()))
                }
            }
        }
    }
    
    // MARK: - Delete Meeting Through Firestore
    func deleteMeeting(meeting: Meeting, completion: @escaping (Result<Void,Error) -> Void) {
        do {
            // Delete the meeting document from Firestore
            try db.collection(collectionName).document(meeting.id).delete {
                error in
                if let error = error {
                    completion(.failure(error))
                }
                else {
                    completion(.success(()))
                }
            }
        }
    }
    // MARK: - // The catch let error will never be triggered because Firestor wont throw errors The setData(from:merge:) method
    func updateMeeting(meeting: Meeting, completion: @escaping (Result<Void,Error) -> Void) {
        db.collection(collectionName).document(meeting.id).setData(from: meeting, merge: true) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
        }
        
    }
        
    
    // MARK: - Fetch Meeting Through Firestore
    func fetchMeeting(meetingId: String, completion: @escaping (Result<Meeting, Error>) -> Void) {
        
        db.collection(collectionName).document(meetingId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let snapshot = snapshot, snapshot.exists else {
                completion(.failure(NSError(domain: "MeetingService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Meeting not found."])))
                return
            }

            do {
                let meeting = try snapshot.data(as: Meeting.self) // Decode Firestore document into Profile
                completion(.success(meeting))
            } catch let error {
                completion(.failure(error))
            }
        }
    }
    
    
    // Note: - First implementation of Batch Processing - Detailed Explanation
    // MARK: -  Accept Meeting Through Firestore
    func acceptMeeting(meetingId: String, userId: String, completion: @escaping (Result<Meeting, Error>) -> Void) {

        // Get the reference to the specific meeting document in Firestore
        // We use the meetingId to pinpoint the correct document in the "meeting" collection
        let meetingRef = db.collection(collectionName).document(meetingId)
        
        // Run a Firestore transaction
        // Transactions are used to ensure that multiple operations happen atomically.
        // All operations within the transaction will either succeed together or fail together.
        db.runTransaction { transaction, errorPointer -> Void in
            do {
                // Attempt to fetch the current state of the meeting document from Firestore
                // The 'transaction.getDocument' method retrieves the document and allows us to read it within the context of the transaction.
                let meetingSnapshot = try transaction.getDocument(meetingRef)
                
                // Decode the document's data into a `Meeting` object
                // If decoding fails (i.e., if the meeting document doesn't exist or its data is malformed), an error is thrown.
                guard var meeting = try meetingSnapshot.data(as: Meeting.self) else {
                    throw NSError(domain: "MeetingService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Meeting not found."])
                }
                
                // Check if the meeting's status is "pending" (i.e., it's waiting to be accepted)
                if meeting.status == "pending" {
                    // If the status is "pending", update the status to "accepted"
                    meeting.status = "accepted"
                    
                    // Add the user to the participants list if they're not already in it
                    // We check if the userId is already in the participants array to avoid duplicates
                    if !meeting.participants.contains(userId) {
                        meeting.participants.append(userId)
                    }
                    
                    // After modifying the meeting object, we save the updated meeting back to Firestore
                    // The 'setData(from:merge:)' method writes the updated `Meeting` object back to Firestore
                    // The 'merge: true' flag ensures that we only update the fields we modified, leaving other fields untouched.
                    try transaction.setData(from: meeting, forDocument: meetingRef, merge: true)

                } else {
                    // If the meeting's status is not "pending", throw an error indicating the meeting cannot be accepted
                    throw NSError(domain: "MeetingService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Meeting cannot be accepted."])
                }

            } catch let error {
                // If an error occurs during the transaction, it’s captured and passed to the errorPointer
                // The errorPointer is a way to communicate the error back to the Firestore transaction system
                errorPointer?.pointee = error as NSError
            }
        } completion: { _, error in
            // Once the transaction is complete (success or failure), we handle the result
            // If the transaction failed, we pass the error to the completion handler
            if let error = error {
                completion(.failure(error))
            } else {
                // If no errors occurred, we indicate success by returning a successful result
                // Here, we could return the updated Meeting, or just indicate success with Void
                completion(.success(()))
            }
        }
    }

        
        
    
    // Function For Generating the Zoom Link
    func generateZoomMeeting() {
        
    }
    
    
    
}
