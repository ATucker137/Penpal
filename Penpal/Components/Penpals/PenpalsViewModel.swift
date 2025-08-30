//
//  PenpalsViewModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//

import Foundation
import FirebaseFirestore
import Combine

/// ViewModel responsible for managing potential penpal matches.
@MainActor
class PenpalsViewModel: ObservableObject {
    @Published var potentialMatches: [PenpalsModel] = [] // Unfiltered matches
    @Published var filteredPotentialMatches: [PenpalsModel] = [] // Filtered matches based off preferences
    @Published var penpalMap: [String: PenpalsModel] = [:]
    @Published var selectedHobby: String = "All"
    @Published var selectedProficiency: String = "All"
    @Published var selectedRegion: String = "All"
    @Published var matchStatus: PenpalStatus? // The current match status of a penpal
    @Published var syncErrorMessage: String? // Holds the error message in case syncing fails
    @Published var syncSuccessMessage: String? // Holds a success message
    @Published var cachedPenpals: [PenpalsModel] = []
    @Published var cachedCount: Int = 0
    // Use your real domain types here
    @Published var lookingFor: LookingFor = .empty
    // MARK: - Swipe limits (server-side, atomic)
    @Published private(set) var remainingSwipes: Int = 0
    @Published private(set) var swipeWindowEndsAt: Date = Date()
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    private var maxDailySwipes: Int = 40

    // session refresh control (optional)
    @Published private(set) var swipesSinceRefresh: Int = 0
    private var refreshEvery: Int = 10         // auto-refresh matches every N successful swipes
    private var lastAutoRefreshAt: Date = .distantPast
    private let autoRefreshMinInterval: TimeInterval = 8 // seconds guard so we don't spam
    private var sessionCancellable: AnyCancellable?
    
    // Stores fetched penpals
    private let penpalService = PenpalsService() // Service layer for handling Firestore operations
    private let userSession: UserSession
    private var userId: String? { userSession.userId }
    private var cancellables = Set<AnyCancellable>()
    private let category = "Penpals ViewModel"
\
    private var sqliteManager = SQLiteManager.shared
    private var acceptedPenpals: [PenpalsModel] = []
    var allHobbies: [String] {
        let hobbies = potentialMatches.flatMap { $0.hobbies.map { $0.name } }
        return Array(Set(hobbies)).sorted()
    }

    var allProficiencies: [String] {
        let profs = potentialMatches.map { $0.proficiency.level.rawValue }
        return Array(Set(profs)).sorted()
    }


    var allRegions: [String] {
        let regions = potentialMatches.map { $0.region }
        return Array(Set(regions)).sorted()
    }

    
    // Inject for testability; default to singleton for app code.
    init(userSession: UserSession = .shared) {
        self.userSession = userSession

        Publishers.CombineLatest3($selectedHobby, $selectedProficiency, $selectedRegion)
            .sink { [weak self] _, _, _ in self?.applyFilters() }
            .store(in: &cancellables)

        // React to login/logout or account switches
        sessionCancellable = userSession.$userId
            .removeDuplicates()
            .receive(on: DispatchQueue.main) // safe even if already on main
            .sink { [weak self] _ in
                self?.refreshSwipeStatus()
                self?.fetchPenpals()
            }
    }
    
    deinit {
        sessionCancellable?.cancel()
    }
    
    // MARK: - Starts listening for profile changes and fetches potential matches.
    func startListeningForMatches() {
        guard let uid = userId else {
            LoggerService.shared.log(.error, "No userId for profile listener", category: category)
            return
        }
        LoggerService.shared.log(.info, "Started listening for profile changes", category: category)
        penpalService.listenForProfileChanges(userId: uid)
    }
    
    // MARK: - Fetch Matches
    func syncAndFetchMatches(userId: String, completion: @escaping (Result<[PenpalsModel], Error>) -> Void) {
        LoggerService.shared.log(.info, "Attempting to fetch matches from Firestore", category: category)
        penpalService.fetchPotentialMatchesFromFirestore(for: userId) { [weak self] result in
            switch result {
            case .success(let matches):
                self?.potentialMatches = matches
                self?.applyFilters()
                self?.sqliteManager.cachePenpals(matches) // keeps local warm
                LoggerService.shared.log(.info, "Successfully fetched and cached \(matches.count) matches", category: self?.category ?? "Unknown")
                completion(.success(matches))
            case .failure:
                LoggerService.shared.log(.error, "Failed to fetch from Firestore. Falling back to local cache", category: self?.category ?? "Unknown")
                let cached = self?.sqliteManager.fetchCachedPenpals(for: userId) ?? []   // ← fix name
                completion(.success(cached))
            }
        }
    }

    
    // MARK: - Fetch Filtered Matches
    func applyFilters() {
        filteredPotentialMatches = potentialMatches.filter { p in
            let hobbyMatch = selectedHobby == "All"
                || p.hobbies.contains { $0.name == selectedHobby }

            let proficiencyMatch = selectedProficiency == "All"
                || p.proficiency.level.rawValue == selectedProficiency

            let regionMatch = selectedRegion == "All"
                || p.region == selectedRegion

            return hobbyMatch && proficiencyMatch && regionMatch
        }
    }
    
    // MARK: - Update Match Status
    func updateMatchStatus(penpalId: String, newStatus: PenpalStatus, userId: String) {
        isLoading = true
        LoggerService.shared.log(.info, "Updating match status to '\(newStatus.rawValue)' for penpal: \(penpalId)", category: category)
        penpalService.updateMatchStatus(penpalId: penpalId, newStatus: newStatus, userId: userId) { success in
            DispatchQueue.main.async {
                self.isLoading = false
                if success {
                    self.matchStatus = newStatus // Update the UI with the new status
                    LoggerService.shared.log(.info, "Successfully updated match status", category: self.category)
                } else {
                    self.errorMessage = "Failed to update match status."
                    LoggerService.shared.log(.error, "Match status update failed", category: self.category)
                }
            }
        }
    }
    
    // MARK: - Send Friend Request
    func sendFriendRequest(to penpalId: String, userId: String) {
        isLoading = true
        LoggerService.shared.log(.info, "Sending friend request to: \(penpalId)", category: category)

        // Optimistic local update
        _ = sqliteManager.sendFriendRequest(to: penpalId, from: userId)

        penpalService.sendFriendRequest(to: penpalId, userId: userId) { success in
            DispatchQueue.main.async {
                self.isLoading = false
                if success {
                    self.errorMessage = nil
                    LoggerService.shared.log(.info, "Friend request sent successfully", category: self.category)
                } else {
                    self.errorMessage = "Failed to send friend request."
                    LoggerService.shared.log(.error, "Failed to send friend request to \(penpalId)", category: self.category)
                }
            }
        }
    }

    // MARK: - Decline Friend Request
    func declineFriendRequest(from penpalId: String, userId: String) {
        isLoading = true
        LoggerService.shared.log(.info, "Declining friend request from: \(penpalId)", category: category)

        penpalService.declineFriendRequest(from: penpalId, userId: userId) { success in
            DispatchQueue.main.async {
                self.isLoading = false
                if success {
                    self.errorMessage = nil
                    _ = self.sqliteManager.declineFriendRequest(from: penpalId, for: userId) // local mirror
                    LoggerService.shared.log(.info, "Successfully declined friend request from: \(penpalId)", category: self.category)
                } else {
                    self.errorMessage = "Failed to decline friend request."
                    LoggerService.shared.log(.error, "Failed to decline friend request", category: self.category)
                }
            }
        }
    }
    
    // MARK: - Accept Friend Request
    func acceptFriendRequest(from penpalId: String, userId: String) {
        isLoading = true
        LoggerService.shared.log(.info, "Accepting friend request from: \(penpalId)", category: category)

        penpalService.acceptFriendRequest(from: penpalId, userId: userId) { success in
            DispatchQueue.main.async {
                self.isLoading = false
                if success {
                    self.errorMessage = nil
                    _ = self.sqliteManager.acceptFriendRequest(from: penpalId, for: userId) // local mirror (status -> approved)
                    LoggerService.shared.log(.info, "Successfully accepted friend request", category: self.category)
                } else {
                    self.errorMessage = "Failed to accept friend request."
                    LoggerService.shared.log(.error, "Failed to accept friend request", category: self.category)
                }
            }
        }
    }
    
    // MARK: - Sync Penpal
    /// Synchronizes penpal data for consistency.
    func syncPenpal(with penpalId: String) {
        isLoading = true
        LoggerService.shared.log(.info, "Attempting to sync penpal: \(penpalId)", category: category)
        penpalService.syncPenpal(with: penpalId) { success, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if success {
                    self.syncSuccessMessage = "Penpal synced successfully."
                    self.syncErrorMessage = nil
                    if let uid = self.userId {
                        self.sqliteManager.syncPenpal(penpalId, for: uid) // mark isSynced locally
                    }
                    LoggerService.shared.log(.info, "Penpal \(penpalId) synced successfully", category: self.category)
                } else {
                    self.syncErrorMessage = error ?? "Error syncing penpal."
                    self.syncSuccessMessage = nil
                    LoggerService.shared.log(.error, "Failed to sync penpal: \(penpalId) — \(error ?? "unknown error")", category: self.category)
                }
            }
        }
    }
    
    // MARK: - Enforce Penpal Limit
    /// Enforces the penpal limit by removing extra requests.
    func enforcePenpalLimit(maxAllowed: Int) {
        LoggerService.shared.log(.debug, "Enforcing penpal limit: max \(maxAllowed)", category: category)
        guard let uid = userId else { return }

        if potentialMatches.count > maxAllowed {
            let excess = potentialMatches.count - maxAllowed
            let extra = potentialMatches.sorted { ($0.matchScore ?? 0) < ($1.matchScore ?? 0) }.prefix(excess)
            LoggerService.shared.log(.info, "Declining \(excess) excess penpals", category: category)
            for p in extra {
                declineFriendRequest(from: p.penpalId, userId: uid)
            }
        }

        // Local cache cleanup to match the UI/state
        sqliteManager.enforcePenpalLimit(for: uid, limit: maxAllowed)
    }
    
    // MARK: -  Delete Penpals
    func deletePenpal(penpalId: String, for userId: String) {
        LoggerService.shared.log(.info, "Attempting to delete penpal: \(penpalId)", category: category)
        penpalService.deletePenpal(penpalId: penpalId, for: userId) { [weak self] result in
            switch result {
            case .success():
                DispatchQueue.main.async {
                    self?.acceptedPenpals.removeAll { $0.penpalId == penpalId }
                    _ = self?.sqliteManager.deletePenpal(penpalId: penpalId, for: userId) // local mirror
                    LoggerService.shared.log(.info, "Deleted penpal from accepted list (remote+local)", category: self?.category ?? "Unknown")
                }
            case .failure(let error):
                LoggerService.shared.log(.error, "Error deleting penpal: \(error.localizedDescription)", category: self?.category ?? "Unknown")
            }
        }
    }
    
    // MARK: - Fetch Penpals
    // This function pulls accepted Penpals
    func fetchApprovedPenpals() {
        guard let uid = userId else {
            LoggerService.shared.log(.error, "No userId for fetchApprovedPenpals", category: category)
            return
        }

        // Local first
        let local = sqliteManager.getAllPenpals(for: uid)
        if !local.isEmpty {
            self.penpalMap = Dictionary(uniqueKeysWithValues: local.map { ($0.penpalId, $0) })
            LoggerService.shared.log(.info, "Loaded \(local.count) approved penpals (local)", category: .sqlitePenpal)
        }

        // Remote refresh
        LoggerService.shared.log(.info, "Attempting to pull all Penpals with status of accepted", category: category)
        penpalService.fetchApprovedPenpals(for: uid) { [weak self] result in
            switch result {
            case .success(let penpals):
                DispatchQueue.main.async {
                    self?.penpalMap = Dictionary(uniqueKeysWithValues: penpals.map { ($0.penpalId, $0) })
                    // Cache to SQLite for next launch/offline
                    self?.sqliteManager.cachePenpals(penpals)
                }
            case .failure(let error):
                LoggerService.shared.log(.error, "Error fetching penpals \(error.localizedDescription)", category: self?.category ?? "Unknown")
            }
        }
    }

    
    // MARK: - Fetch Penpals
    func fetchPenpals() {
        guard let uid = userId else {
            LoggerService.shared.log(.error, "No userId found in UserSession", category: category)
            return
        }

        // Local first (instant UI)
        let local = sqliteManager.fetchCachedPenpals(for: uid)
        if !local.isEmpty {
            self.potentialMatches = local
            self.applyFilters()
            LoggerService.shared.log(.info, "Loaded \(local.count) cached penpals (local-first)", category: .sqlitePenpal)
        }

        // Remote refresh (and cache happens inside syncAndFetchMatches)
        syncAndFetchMatches(userId: uid) { [weak self] result in
            switch result {
            case .success(let matches):
                DispatchQueue.main.async {
                    self?.potentialMatches = matches
                    self?.applyFilters()
                }
            case .failure(let error):
                LoggerService.shared.log(.error, "Failed to fetch penpals: \(error.localizedDescription)", category: self?.category ?? "Penpals VM")
            }
        }
    }


    
    // MARK: - Cache Penpals Also Goes Here?
    // Fetch list (off main), then publish on main
    func fetchCachedPenpals() {
        guard let userId = userSession.userId else {
            LoggerService.shared.log(.error, "No userId in session", category: category)
            return
        }
        Task {
            let list = await Task.detached { [sqliteManager] in
                sqliteManager.fetchCachedPenpals(for: userId)
            }.value
            self.cachedPenpals = list
            self.cachedCount = list.count
            LoggerService.shared.log(.info, "Loaded \(list.count) cached penpals", category: .sqlitePenpal)
        }
    }
    
    // MARK: - Count Cached Penpals
    // Count only (off main), then publish on main
    func countCachedPenpals() {
        guard let userId = userSession.userId else {
            LoggerService.shared.log(.error, "No userId in session", category: .sqlitePenpal)
            return
        }
        Task {
            let count = await Task.detached { [sqliteManager] in
                sqliteManager.countCachedPenpals(for: userId)
            }.value
            self.cachedCount = count
            LoggerService.shared.log(.info, "Cached penpal count: \(count)", category: .sqlitePenpal)
        }
    }
    
    

    struct LookingFor: Equatable, Codable {
        var hobbies: [Hobbies]           // your class (id/name/emoji)
        var regions: [String]            // you currently store region as String
        var proficiency: ProficiencyLevel?  // target partner’s level (not full LanguageProficiency)
        var language: Language?          // optional: if you want to constrain language

        static let empty = LookingFor(hobbies: [], regions: [], proficiency: nil, language: nil)
    }

    // MARK: - Save "Looking For" prefs
    func updateLookingFor(_ value: LookingFor) {
        guard let uid = userId else {
            LoggerService.shared.log(.error, "updateLookingFor: missing userId", category: category)
            return
        }

        LoggerService.shared.log(
            .info,
            """
            updateLookingFor: saving prefs \
            (hobbies:\(value.hobbies.count), regions:\(value.regions.count), \
            proficiency:\(value.proficiency?.rawValue ?? "nil"), \
            language:\(value.language?.languageCode ?? "nil"))
            """,
            category: category
        )

        lookingFor = value
        let prefs = PenpalsService.LookingForPrefs(
            hobbyIds: value.hobbies.map { $0.id },
            regions: value.regions,
            proficiencyLevel: value.proficiency?.rawValue,
            languageCode: value.language?.languageCode
        )

        penpalService.updateLookingFor(userId: uid, prefs: prefs) { [weak self] ok in
            guard let self = self else { return }
            if ok {
                LoggerService.shared.log(.info, "updateLookingFor: saved to Firestore", category: self.category)
                self.applyFilters()
            } else {
                self.syncErrorMessage = "Couldn’t save preferences."
                LoggerService.shared.log(.error, "updateLookingFor: Firestore save failed", category: self.category)
            }
        }
    }

    // MARK: - Load "Looking For" prefs
    func loadLookingFor() {
        guard let uid = userId else {
            LoggerService.shared.log(.error, "loadLookingFor: missing userId", category: category)
            return
        }
        LoggerService.shared.log(.info, "loadLookingFor: fetching from Firestore", category: category)

        penpalService.fetchLookingFor(userId: uid) { [weak self] prefs in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.lookingFor = prefs
                LoggerService.shared.log(
                    .info,
                    """
                    loadLookingFor: loaded \
                    (hobbies:\(prefs.hobbies.count), regions:\(prefs.regions.count), \
                    proficiency:\(prefs.proficiency?.rawValue ?? "nil"), \
                    language:\(prefs.language?.languageCode ?? "nil"))
                    """,
                    category: self.category
                )
                self.applyFilters()
            }
        }
    }

    // MARK: - Configure swipe quota
    func configureSwipeQuota(maxPerDay: Int = 40, autoRefreshEvery: Int = 10) {
        LoggerService.shared.log(.info, "configureSwipeQuota: maxPerDay=\(maxPerDay), autoRefreshEvery=\(autoRefreshEvery)", category: category)
        self.maxDailySwipes = maxPerDay
        self.refreshEvery = max(1, autoRefreshEvery)

        if let uid = userId {
            // Reset/align the local row for today (idempotent)
            _ = sqliteManager.setDailySwipeAllowanceLocal(userId: uid, newMax: maxPerDay)
        }

        refreshSwipeStatus()
    }
    
    private func maybeAutoRefreshMatches() {
        guard swipesSinceRefresh >= refreshEvery else { return }
        guard Date().timeIntervalSince(lastAutoRefreshAt) >= autoRefreshMinInterval else { return }

        lastAutoRefreshAt = Date()
        swipesSinceRefresh = 0
        LoggerService.shared.log(.info, "Auto-refreshing matches after \(refreshEvery) swipes", category: category)

        fetchPenpals()
    }

    // MARK: - Refresh swipe status
    func refreshSwipeStatus() {
        guard let uid = userId else {
            LoggerService.shared.log(.error, "refreshSwipeStatus: missing userId", category: category)
            return
        }

        // Local-first snapshot (fast + offline)
        let local = sqliteManager.fetchSwipeStatusLocal(userId: uid, defaultMax: maxDailySwipes)
        self.remainingSwipes = local.remaining
        self.swipeWindowEndsAt = local.windowEndsAt
        LoggerService.shared.log(.info, "refreshSwipeStatus(local): remaining=\(local.remaining), windowEndsAt=\(local.windowEndsAt)", category: category)

        // Server refresh → write-through to SQLite
        penpalService.fetchSwipeStatus(userId: uid, maxPerDay: maxDailySwipes) { [weak self] remaining, endsAt in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.remainingSwipes = remaining
                self.swipeWindowEndsAt = endsAt
                self.sqliteManager.upsertSwipeStatusLocal(userId: uid, remaining: remaining, maxPerDay: self.maxDailySwipes)
                LoggerService.shared.log(.info, "refreshSwipeStatus(remote): remaining=\(remaining), windowEndsAt=\(endsAt)", category: self.category)
            }
        }
    }


    // MARK: - Try to consume 1 swipe and run action
    func trySwipe(perform action: @escaping () -> Void,
                  outOfSwipes: @escaping () -> Void = { }) {
        guard let uid = userId else {
            LoggerService.shared.log(.error, "trySwipe: missing userId", category: category)
            outOfSwipes()
            return
        }

        LoggerService.shared.log(.info, "trySwipe: attempting consume for user \(uid)", category: category)

        penpalService.tryConsumeSwipe(userId: uid, maxPerDay: maxDailySwipes) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let remaining):
                    self.remainingSwipes = remaining
                    self.sqliteManager.upsertSwipeStatusLocal(userId: uid, remaining: remaining, maxPerDay: self.maxDailySwipes)
                    LoggerService.shared.log(.info, "trySwipe(remote): remaining=\(remaining)", category: self.category)

                    if remaining >= 0 {
                        action()
                        self.swipesSinceRefresh += 1
                        self.maybeAutoRefreshMatches()
                    } else {
                        outOfSwipes()
                    }

                case .failure(let error):
                    LoggerService.shared.log(.warning, "trySwipe(remote) failed: \(error.localizedDescription). Falling back to local.", category: self.category)

                    switch self.sqliteManager.tryConsumeSwipeLocal(userId: uid, maxPerDay: self.maxDailySwipes) {
                    case .success(let remainingLocal):
                        self.remainingSwipes = remainingLocal
                        LoggerService.shared.log(.info, "trySwipe(local): remaining=\(remainingLocal)", category: self.category)

                        if remainingLocal >= 0 {
                            action()
                            self.swipesSinceRefresh += 1
                            self.maybeAutoRefreshMatches()
                        } else {
                            outOfSwipes()
                        }

                    case .failure(let e):
                        LoggerService.shared.log(.error, "tryConsumeSwipeLocal failed: \(e.localizedDescription)", category: self.category)
                        outOfSwipes()
                    }
                }
            }
        }
    }
    
    func setDailySwipeAllowance(_ newMax: Int) {
        guard let uid = userId else { return }
        maxDailySwipes = max(0, newMax)
        _ = sqliteManager.setDailySwipeAllowanceLocal(userId: uid, newMax: newMax)
        penpalService.setDailySwipeAllowance(userId: uid, newMax: newMax) { [weak self] _ in
            self?.refreshSwipeStatus()
        }
    }

    func grantBonusSwipes(_ amount: Int) {
        guard let uid = userId else { return }
        _ = sqliteManager.grantBonusSwipesLocal(userId: uid, amount: amount, maxPerDay: maxDailySwipes)
        penpalService.grantBonusSwipes(userId: uid, amount: amount, maxPerDay: maxDailySwipes) { [weak self] _ in
            self?.refreshSwipeStatus()
        }
    }


    // MARK: - View helpers
    func like(_ penpal: PenpalsModel, gated: Bool = true) {
        guard let uid = userId else {
            LoggerService.shared.log(.error, "like: missing userId", category: category)
            return
        }
        let doSend = { [weak self] in
            self?.sendFriendRequest(to: penpal.penpalId, userId: uid)
        }
        if gated {
            trySwipe(perform: doSend, outOfSwipes: { [weak self] in
                LoggerService.shared.log(.info, "like: out of swipes", category: self?.category ?? "Penpals VM")
                self?.presentOutOfSwipesMessage()
            })
        } else {
            doSend()
        }
    }

    // MARK: - Pass
    func pass(_ penpal: PenpalsModel, gated: Bool = true) {
        guard let uid = userId else {
            LoggerService.shared.log(.error, "pass: missing userId", category: category)
            return
        }
        let doDecline = { [weak self] in
            self?.declineFriendRequest(from: penpal.penpalId, userId: uid)
        }
        if gated {
            trySwipe(perform: doDecline, outOfSwipes: { [weak self] in
                LoggerService.shared.log(.info, "pass: out of swipes", category: self?.category ?? "Penpals VM")
                self?.presentOutOfSwipesMessage()
            })
        } else {
            doDecline()
        }
    }

    // MARK: - Out of swipes UX
    private func presentOutOfSwipesMessage() {
        let msg = "You’re out of swipes. More in \(timeUntilResetString())."
        syncErrorMessage = msg
        LoggerService.shared.log(.info, "presentOutOfSwipesMessage: \(msg)", category: category)
    }

    private func timeUntilResetString() -> String {
        let now = Date()
        let interval = max(0, swipeWindowEndsAt.timeIntervalSince(now))
        let f = DateComponentsFormatter()
        f.allowedUnits = [.hour, .minute]
        f.unitsStyle = .short
        return f.string(from: interval) ?? "a bit"
    }
    // MARK: - Clear Old Penpals

    // TODO: - Notify The User Penpal On People that want user to be their penpal
    
    
    
}


