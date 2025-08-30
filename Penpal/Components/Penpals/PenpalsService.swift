//
//  PenpalsService.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//
import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth

final class PenpalsService {
    private let db = Firestore.firestore()
    private var profileListener: ListenerRegistration?
    private let category = "PenpalsService"

    // MARK: - Firestore wire prefs (primitive types)
    struct LookingForPrefs: Codable {
        let hobbyIds: [String]
        let regions: [String]
        let proficiencyLevel: String?   // ProficiencyLevel.rawValue
        let languageCode: String?       // Language.languageCode
    }

    // MARK: - Profile changes
    func listenForProfileChanges(userId: String) {
        LoggerService.shared.log(.info, "Listening for profile changes for user: \(userId)", category: category)
        profileListener?.remove()
        profileListener = db.collection("users").document(userId).addSnapshotListener { [weak self] _, error in
            if let error = error {
                LoggerService.shared.log(.error, "Profile listener error: \(error.localizedDescription)", category: self?.category ?? "PenpalsService")
            } else {
                LoggerService.shared.log(.info, "Profile changed for \(userId)", category: self?.category ?? "PenpalsService")
            }
        }
    }

    deinit { profileListener?.remove() }

    // MARK: - Looking For (save/load)
    func updateLookingFor(userId: String, prefs: LookingForPrefs, completion: @escaping (Bool) -> Void) {
        let doc = db.collection("users").document(userId)
        let payload: [String: Any] = [
            "lookingFor": [
                "hobbyIds": prefs.hobbyIds,
                "regions": prefs.regions,
                "proficiencyLevel": prefs.proficiencyLevel as Any,
                "languageCode": prefs.languageCode as Any
            ],
            "updatedAt": FieldValue.serverTimestamp()
        ]
        doc.setData(payload, merge: true) { err in completion(err == nil) }
    }

    func fetchLookingFor(userId: String, completion: @escaping (PenpalsViewModel.LookingFor) -> Void) {
        db.collection("users").document(userId).getDocument { snap, _ in
            let lf = (snap?.data()?["lookingFor"] as? [String: Any]) ?? [:]
            let hobbyIds = lf["hobbyIds"] as? [String] ?? []
            let regions = lf["regions"] as? [String] ?? []
            let profRaw = lf["proficiencyLevel"] as? String
            let langCode = lf["languageCode"] as? String

            let hobbies = hobbyIds.compactMap { id in Hobbies.predefinedHobbies.first { $0.id == id } }
            let proficiency = profRaw.flatMap { ProficiencyLevel(rawValue: $0) }
            let language = langCode.flatMap { code in Language.predefinedLanguages.first { $0.languageCode == code } }

            completion(PenpalsViewModel.LookingFor(hobbies: hobbies, regions: regions, proficiency: proficiency, language: language))
        }
    }

    // MARK: - Fetch potential matches (pre-calculated feed)
    func fetchPotentialMatchesFromFirestore(for userId: String, completion: @escaping (Result<[PenpalsModel], Error>) -> Void) {
        db.collection("potentialMatches")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error)); return
                }

                let matches: [PenpalsModel] = (snapshot?.documents ?? []).compactMap { doc in
                    let data = doc.data()

                    guard
                        let penpalId = data["penpalId"] as? String,
                        let firstName = data["firstName"] as? String,
                        let lastName = data["lastName"] as? String,
                        let region = data["region"] as? String,
                        let profileImageURL = data["profileImageURL"] as? String,
                        let statusRaw = data["status"] as? String,
                        let status = PenpalStatus(rawValue: statusRaw)
                    else { return nil }

                    // proficiency dict → LanguageProficiency
                    let proficiency: LanguageProficiency = {
                        if let dict = data["proficiency"] as? [String: Any],
                           let p = LanguageProficiency.fromDict(dict) { return p }
                        // fallback default to avoid crash
                        return LanguageProficiency(language: Language(id: "1", name: "English", languageCode: "en"), level: .beginner, isNative: false)
                    }()

                    // hobbies [String] (ids/names) → [Hobbies]
                    let hobbyTokens = (data["hobbies"] as? [String]) ?? []
                    let hobbies: [Hobbies] = hobbyTokens.compactMap { token in
                        Hobbies.predefinedHobbies.first { $0.id == token || $0.name == token }
                    }

                    // goal dict → Goals?
                    var goal: Goals? = nil
                    if let goalDict = data["goal"] as? [String: Any] {
                        goal = Goals.fromDict(goalDict)
                    } else if let goalId = data["goalId"] as? String {
                        goal = Goals.all.first(where: { $0.id == goalId })
                    }

                    let matchScore = data["matchScore"] as? Int
                    let isSynced = data["isSynced"] as? Bool ?? false

                    return PenpalsModel(
                        userId: userId,
                        penpalId: penpalId,
                        firstName: firstName,
                        lastName: lastName,
                        proficiency: proficiency,
                        hobbies: hobbies,
                        goal: goal,
                        region: region,
                        matchScore: matchScore,
                        status: status,
                        profileImageURL: profileImageURL,
                        isSynced: isSynced
                    )
                }

                LoggerService.shared.log(.info, "Fetched \(matches.count) potential matches", category: self.category)
                completion(.success(matches))
            }
    }

    // MARK: - Optional: batch write potential matches
    func updatePotentialMatches(userId: String, matches: [PenpalsModel], completion: ((Bool) -> Void)? = nil) {
        let batch = db.batch()
        let col = db.collection("potentialMatches")

        for m in matches {
            let ref = col.document("\(userId)_\(m.penpalId)")
            var data: [String: Any] = [
                "userId": userId,
                "penpalId": m.penpalId,
                "firstName": m.firstName,
                "lastName": m.lastName,
                "region": m.region,
                "proficiency": m.proficiency.toDict(),
                "hobbies": m.hobbies.map { $0.id },
                "profileImageURL": m.profileImageURL,
                "status": m.status.rawValue,
                "isSynced": m.isSynced,
                "updatedAt": FieldValue.serverTimestamp()
            ]
            if let goalDict = m.goal?.toDict() { data["goal"] = goalDict }
            if let score = m.matchScore { data["matchScore"] = score }
            batch.setData(data, forDocument: ref, merge: true)
        }

        batch.commit { err in
            completion?(err == nil)
        }
    }

    // MARK: - Match status & requests
    func updateMatchStatus(penpalId: String, newStatus: PenpalStatus, userId: String, completion: @escaping (Bool) -> Void) {
        let ref = db.collection("potentialMatches").document("\(userId)_\(penpalId)")
        ref.updateData([
            "status": newStatus.rawValue,
            "updatedAt": FieldValue.serverTimestamp()
        ]) { error in completion(error == nil) }
    }

    func sendFriendRequest(to penpalId: String, userId: String, completion: @escaping (Bool) -> Void) {
        LoggerService.shared.log(.info, "Sending friend request to \(penpalId)", category: category)
        let ref = db.collection("potentialMatches").document("\(userId)_\(penpalId)")
        ref.setData([
            "userId": userId,
            "penpalId": penpalId,
            "status": PenpalStatus.pending.rawValue,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true) { error in completion(error == nil) }
    }

    func declineFriendRequest(from penpalId: String, userId: String, completion: @escaping (Bool) -> Void) {
        let ref = db.collection("potentialMatches").document("\(userId)_\(penpalId)")
        ref.setData([
            "userId": userId,
            "penpalId": penpalId,
            "status": PenpalStatus.declined.rawValue,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true) { error in completion(error == nil) }
    }

    func acceptFriendRequest(from penpalId: String, userId: String, completion: @escaping (Bool) -> Void) {
        let ref = db.collection("potentialMatches").document("\(userId)_\(penpalId)")
        ref.setData([
            "userId": userId,
            "penpalId": penpalId,
            "status": PenpalStatus.approved.rawValue,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true) { error in completion(error == nil) }
    }


    // MARK: - Sync Penpal into subcollection
    /// VM calls: penpalService.syncPenpal(with: penpalId) { success, error in ... }
    func syncPenpal(with penpalId: String, completion: @escaping (Bool, String?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false, "No authenticated user"); return
        }
        LoggerService.shared.log(.info, "Sync penpal \(penpalId) for \(uid)", category: category)
        let ref = db.collection("users").document(uid).collection("penpals").document(penpalId)
        ref.setData([
            "status": PenpalStatus.approved.rawValue,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true) { error in
            if let error = error {
                completion(false, error.localizedDescription)
            } else {
                completion(true, nil)
            }
        }
    }

    // MARK: - Delete & fetch approved penpals
    func deletePenpal(penpalId: String, for userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let ref = db.collection("users").document(userId).collection("penpals").document(penpalId)
        ref.delete { error in
            if let error = error { completion(.failure(error)) }
            else { completion(.success(())) }
        }
    }

    func fetchApprovedPenpals(for userId: String, completion: @escaping (Result<[PenpalsModel], Error>) -> Void) {
        db.collection("users").document(userId).collection("penpals")
            .whereField("status", isEqualTo: PenpalStatus.approved.rawValue)
            .getDocuments { snapshot, error in
                if let error = error { completion(.failure(error)); return }
                let list: [PenpalsModel] = (snapshot?.documents ?? []).compactMap {
                    PenpalsModel.fromFireStoreData($0.data())
                }
                completion(.success(list))
            }
    }

    // MARK: - Swipe limits (atomic)
    func tryConsumeSwipe(userId: String, maxPerDay: Int, completion: @escaping (Result<Int, Error>) -> Void) {
        let doc = db.collection("rateLimits").document(userId)
        let todayKey = Self.dayKeyFormatter.string(from: Date())

        db.runTransaction({ txn, _ -> Any? in
            let snap: DocumentSnapshot
            do {
                snap = try txn.getDocument(doc)
            } catch {
                // First swipe today: create doc and count this swipe
                txn.setData([
                    "used": 1,
                    "max": maxPerDay,
                    "day": todayKey,
                    "updatedAt": FieldValue.serverTimestamp()
                ], forDocument: doc, merge: true)
                return ["remaining": max(0, maxPerDay - 1)]
            }

            var data = snap.data() ?? [:]
            let day = (data["day"] as? String) ?? todayKey
            var used = (data["used"] as? Int) ?? 0
            let maxVal = (data["max"] as? Int) ?? maxPerDay

            if day != todayKey { used = 0; data["day"] = todayKey }

            guard used < maxVal else {
                // Signal blocked (don’t throw → VM won’t fall back to local)
                txn.setData(["day": day, "used": used, "max": maxVal], forDocument: doc, merge: true)
                return "BLOCKED"
            }

            used += 1
            data["used"] = used
            data["max"] = maxVal
            data["updatedAt"] = FieldValue.serverTimestamp()
            txn.setData(data, forDocument: doc, merge: true)
            return ["remaining": max(0, maxVal - used)]
        }) { result, error in
            if let error = error { completion(.failure(error)); return }
            if let marker = result as? String, marker == "BLOCKED" { completion(.success(-1)); return }
            if let dict = result as? [String: Int], let remaining = dict["remaining"] { completion(.success(remaining)); return }

            // Fallback (should be rare)
            doc.getDocument { snap, _ in
                let used = snap?.data()?["used"] as? Int ?? 0
                let maxVal = snap?.data()?["max"] as? Int ?? maxPerDay
                completion(.success(max(0, maxVal - used)))
            }
        }
    }



    func fetchSwipeStatus(userId: String, maxPerDay: Int, completion: @escaping (_ remaining: Int, _ windowEndsAt: Date) -> Void) {
        let doc = db.collection("rateLimits").document(userId)
        let todayKey = Self.dayKeyFormatter.string(from: Date())
        doc.getDocument { snap, _ in
            let data = snap?.data() ?? [:]
            let day = (data["day"] as? String) ?? todayKey
            let used = (data["used"] as? Int) ?? 0
            let maxVal = (data["max"] as? Int) ?? maxPerDay
            let remaining = (day == todayKey) ? max(0, maxVal - used) : maxVal
            let windowEnds = Calendar.current.startOfDay(for: Date()).addingTimeInterval(24 * 60 * 60)
            completion(remaining, windowEnds)
        }
    }

    func grantBonusSwipes(userId: String, amount: Int, maxPerDay: Int, completion: @escaping (Bool) -> Void) {
        guard amount > 0 else { completion(false); return }
        let doc = db.collection("rateLimits").document(userId)
        db.runTransaction({ txn, _ -> Any? in
            let snap = try txn.getDocument(doc)
            let todayKey = Self.dayKeyFormatter.string(from: Date())
            var data = snap.data() ?? [:]
            let day = (data["day"] as? String) ?? todayKey
            var used = (data["used"] as? Int) ?? 0
            let maxVal = (data["max"] as? Int) ?? maxPerDay
            if day != todayKey { used = 0; data["day"] = todayKey }
            used = max(0, used - amount)
            data["used"] = used
            data["max"] = maxVal
            data["updatedAt"] = FieldValue.serverTimestamp()
            txn.setData(data, forDocument: doc, merge: true)
            return nil
        }) { _, error in
            completion(error == nil)
        }
    }

    func setDailySwipeAllowance(userId: String, newMax: Int, completion: @escaping (Bool) -> Void) {
        db.collection("rateLimits").document(userId)
            .setData(["max": max(0, newMax),
                      "updatedAt": FieldValue.serverTimestamp()],
                     merge: true) { err in completion(err == nil) }
    }

    private static let dayKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar.current
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    
    
}
