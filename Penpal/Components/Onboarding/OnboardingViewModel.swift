//
//  OnboardingViewModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 8/23/25.
//


/*
 TODO: App flow + navigation paths (simple + concrete)

 HIGH-LEVEL STATES
 -----------------
 1) LoggedOut
 2) LoggedInNeedsOnboarding (user has account but no profile)
 3) LoggedInReady (user + profile complete)

 CONTENT VIEW (root switchboard)
 -------------------------------
 - On appear: userSession.loadSession()
 - Branch:
   - if !userSession.isLoggedIn          -> show AuthFlow()
   - else if profileVM.needsOnboarding   -> show OnboardingFlow()
   - else                                -> show MainTabView()

 SIMPLE PATH (happy path)
 ------------------------
 PenpalApp -> ContentView
  ├─[LoggedOut]────────────┐
  │                        v
  │                    AuthFlow
  │                      └─ Login or SignUp -> Auth success -> userSession.isLoggedIn = true
  │                                             v
  ├─[LoggedInNeedsOnboarding]──────────────  OnboardingFlow
  │                                              └─ Steps -> Submit -> profile created
  │                                                  -> profileVM.needsOnboarding = false
  │                                                      v
  └─[LoggedInReady]────────────────────────── MainTabView (Home | Penpals | Messages | Study | Profile)

 AUTH FLOW (routes)
 ------------------
 - Welcome (choose "Log in" or "Sign up")
 - LoginView (email/password or OAuth)
   -> On success: AuthManager sets current user; userSession.saveSession(...)
   -> ContentView re-evaluates; if profile missing -> OnboardingFlow else MainTabView
 - SignUpView (collect email/password)
   -> Create account -> (optional) email verify -> proceed like Login success

 ONBOARDING FLOW (routes / steps)
 --------------------------------
 enum OnboardingRoute {
   case welcome      // optional, if you want a first-time intro slide
   case name         // firstName, lastName
   case photo        // pick/upload profile photo
   case region       // region, country
   case hobbies      // multi-select
   case languages    // fluent + learning + proficiency
   case lookingFor   // target partner prefs (level, regions, hobbies, language)
   case notifications// toggles for reminders/updates (optional)
   case review       // summary & confirm
 }
 - Flow: welcome -> name -> photo -> region -> hobbies -> languages -> lookingFor -> notifications -> review -> SUBMIT
 - On submit:
     profileViewModel.createUserProfile(...)
     -> mark profileVM.needsOnboarding = false
     -> navigate back to ContentView -> MainTabView

 MAIN TAB VIEW
 -------------
 Tabs (enum Tab { case home, penpals, messages, study, profile })
 - HomeView
   - shows greeting + weekly insights + "Your Penpals"
   - button: "My Calendar" -> MyCalendarView
   - MyCalendarView -> select day -> Meeting cards -> MeetingView
     - MeetingView -> TopicView / ScheduleMeetingTimeView
 - PenpalsView
   - swipe feed, filters, like/pass, swipe limit
 - Messages
   - Conversations list -> ConversationDetailView
 - Study (VocabSheetView)
 - Profile
   - ProfileView -> EditProfileView

 VIEW MODEL OWNERSHIP & INJECTION
 --------------------------------
 - ContentView:
     @StateObject private var profileVM  = ProfileViewModel()
     @StateObject private var messagesVM = MessagesViewModel()
     @StateObject private var penpalsVM  = PenpalsViewModel()
   Then inject via .environmentObject(...) so all tabs can share them.
 - UserSession is injected at the app root (PenpalApp) as .environmentObject(userSession).
 - Avoid using UserSession.shared inside views; prefer @EnvironmentObject var userSession: UserSession.

 WHEN TO USE @StateObject vs @EnvironmentObject
 ----------------------------------------------
 - @StateObject where the view OWNS the VM lifecycle (e.g., ContentView creates the shared VMs).
 - @EnvironmentObject in child views that CONSUME those shared VMs (HomeView, PenpalsView, etc).

 ROUTING NOTES (NavigationStack)
 -------------------------------
 - AuthFlow: Welcome -> (Login | SignUp). On success, pop to root (ContentView will switch branch).
 - OnboardingFlow: use a pager or route enum + NavigationStack. On finish, set flag and return to ContentView.
 - MainTabView: keep tabs independent; deep links handled by optional bindings/paths if needed.

 EDGE CASES / TODO
 -----------------
 - Detect "needsOnboarding": profileVM.checkIfProfileExists() after login; set needsOnboarding accordingly.
 - Handle network errors in Auth/Onboarding gracefully with retry.
 - Persist partial onboarding progress locally if user quits mid-flow (optional).
 - Disable back-swipe on critical onboarding steps to avoid exiting unintentionally (optional).
 - Logout flow: userSession.clear(); reset shared VMs (profile/messages/penpals) if necessary.
 - Deep link to Messages or Meeting: pass selectedTab + target IDs through MainTabView to the right subview.

 PSEUDOCODE SKETCHES
 -------------------
 // ContentView
 if !session.isLoggedIn {
   AuthFlow()
 } else if profileVM.needsOnboarding {
   OnboardingFlow()
 } else {
   MainTabView()
 }

 // After login/signup success
 session.saveSession(userId: uid, email: ...)
 profileVM.checkIfProfileExists() // async; set needsOnboarding
 // ContentView will re-render & route

 // Onboarding submit
 profileVM.createUserProfile(...) { success in
   if success { profileVM.needsOnboarding = false }
 }

*/
import SwiftUI
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {

    // MARK: Steps
    enum Step: Int, CaseIterable { case welcome, name, region, hobbies, languages, review }

    // MARK: Draft (what the user fills out)
    struct Draft: Codable, Equatable {
        var firstName: String = ""
        var lastName:  String = ""
        var region:    String = ""
        var country:   String = ""
        // Prefer Set to avoid dupes; order doesn’t matter here
        var hobbies:   Set<Hobbies> = []

        // Your typed language objects
        var native: Language? = nil
        var target: Language? = nil
        var targetLevel: ProficiencyLevel = .beginner

        // Goals are typed too; Set avoids duplicates
        var goals:     Set<Goals> = []
    }

    // MARK: Persisted payload for UserDefaults
    private struct Persisted: Codable {
        let version: Int
        let userId: String?
        let stepRaw: Int
        let draft: Draft
        let updatedAt: Date
    }

    // MARK: Published
    @Published var step: Step = .welcome
    @Published var draft = Draft()
    @Published var isSubmitting = false
    @Published var errorMessage: String?

    // MARK: Derived
    var progress: Double {
        guard let idx = Step.allCases.firstIndex(of: step) else { return 0 }
        return Double(idx + 1) / Double(Step.allCases.count)
    }
    var isFirstStep: Bool { step == .welcome }
    var isLastStep:  Bool { step == .review }

    // MARK: Dependencies
    private let profileVM: ProfileViewModel
    private let userId: String?

    // MARK: Storage
    private let version = 1
    private let storage = UserDefaults.standard
    private var autosaveCancellable: AnyCancellable?

    private var progressKey: String {
        let uid = userId ?? "anon"
        return "onboarding.v\(version).\(uid).progress"
    }

    // MARK: Init
    init(profileVM: ProfileViewModel, userId: String?) {
        self.profileVM = profileVM
        self.userId = userId
        restoreProgressIfAny()
        setupAutoSave()
    }

    // MARK: Navigation
    func next() {
        guard canAdvance(),
              let i = Step.allCases.firstIndex(of: step),
              i < Step.allCases.index(before: Step.allCases.endIndex) else { return }
        step = Step.allCases[Step.allCases.index(after: i)]
        saveProgress()
    }

    func back() {
        guard let i = Step.allCases.firstIndex(of: step),
              i > Step.allCases.startIndex else { return }
        step = Step.allCases[Step.allCases.index(before: i)]
        // (Optional) save here too if you want
    }

    // MARK: Validation
    func canAdvance() -> Bool {
        switch step {
        case .welcome:
            return true
        case .name:
            return !draft.firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
                   !draft.lastName.trimmingCharacters(in: .whitespaces).isEmpty
        case .region:
            return !draft.region.isEmpty && !draft.country.isEmpty
        case .hobbies:
            return !draft.hobbies.isEmpty
        case .languages:
            return draft.native
        case .review:
            return true
        }
    }

    // MARK: Submit
    func submit(completion: @escaping (Bool) -> Void) {
        isSubmitting = true
        errorMessage = nil

        // Copy into your ProfileViewModel (map to your real types if needed)
        profileVM.firstName = draft.firstName
        profileVM.lastName  = draft.lastName
        profileVM.region    = draft.region
        profileVM.country   = draft.country
        profileVM.hobbies   = draft.hobbies
        profileVM.goals     = draft.goals

        profileVM.createUserProfile { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                self.isSubmitting = false
                switch result {
                case .success:
                    self.clearProgress()
                    completion(true)
                case .failure(let err):
                    self.errorMessage = err.localizedDescription
                    completion(false)
                }
            }
        }
    }

    // MARK: Progress persistence
    private func saveProgress() {
        let payload = Persisted(
            version: version,
            userId: userId,
            stepRaw: step.rawValue,
            draft: draft,
            updatedAt: Date()
        )
        if let data = try? JSONEncoder().encode(payload) {
            storage.set(data, forKey: progressKey)
        }
    }

    private func clearProgress() {
        storage.removeObject(forKey: progressKey)
    }

    private func restoreProgressIfAny() {
        guard let data = storage.data(forKey: progressKey),
              let persisted = try? JSONDecoder().decode(Persisted.self, from: data)
        else { return }

        // Version check (you could migrate instead)
        guard persisted.version == version else {
            storage.removeObject(forKey: progressKey)
            return
        }

        // Optional: ensure same user
        if let persistedUid = persisted.userId,
           let currentUid = userId,
           persistedUid != currentUid {
            return
        }

        // Restore
        self.draft = persisted.draft

        // Restore step but clamp to valid earliest allowed
        let preferred = Step(rawValue: persisted.stepRaw) ?? .welcome
        self.step = earliestAllowedStep(for: draft, preferred: preferred)
    }

    private func earliestAllowedStep(for draft: Draft, preferred: Step) -> Step {
        if draft.firstName.trimmingCharacters(in: .whitespaces).isEmpty ||
           draft.lastName.trimmingCharacters(in: .whitespaces).isEmpty {
            return .name
        }
        if draft.region.isEmpty || draft.country.isEmpty {
            return .region
        }
        if draft.hobbies.isEmpty {
            return .hobbies
        }
        if draft.fluent.isEmpty || draft.learning.isEmpty {
            return .languages
        }
        if draft.native == nil || draft.target == nil {
            return .languages
        }
        return Step.allCases.contains(preferred) ? preferred : .review
    }

    // MARK: Debounced autosave
    private func setupAutoSave() {
        autosaveCancellable = Publishers.CombineLatest($draft, $step)
            .removeDuplicates { lhs, rhs in lhs == rhs } // Draft is Equatable above
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .sink { [weak self] _, _ in
                self?.saveProgress()
            }
    }
}
