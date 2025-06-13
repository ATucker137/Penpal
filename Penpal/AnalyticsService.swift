//
//  AnalyticsService.swift
//  Penpal
//
//  Created by Austin William Tucker on 4/14/25.
//

// AnalyticsService.swift


/*
  **How to View Events in Firebase Analytics**

  1. **Firebase Console**:
      - Go to the Firebase Console: https://console.firebase.google.com/
      - Select your Firebase project (e.g., "Penpal").
      - Navigate to the "Analytics" section in the left sidebar, then click on "Events."
      - Here, you will see a list of events that have been triggered in your app, such as `profile_creation`, `set_language_goals`, `message_sent`, and `penpal_connection`.

  2. **Event Parameters**:
      - Firebase Analytics automatically logs event parameters like `user_id`, `region`, `language`, etc., which can be viewed within the event details.
      - You can filter and analyze the events based on these parameters. For example, you can analyze how many users created profiles in a particular region or how many users set specific language goals.

  3. **Real-time Reporting**:
      - You can check "Real-time" reports in Firebase Analytics to get immediate feedback on whether events are being triggered correctly during app usage.

  4. **Debugging**:
      - You can enable Debug mode to verify that events are being logged correctly while testing the app. To enable Debug mode, use the following command in your terminal (for iOS devices connected to Xcode):
          ```
          adb shell setprop debug.firebase.analytics.app <your_app_id>
          ```
      - This ensures that events are logged during testing, so you can see them in the Firebase DebugView.

  **Analyzing Data**:
  - Once events are logged and start accumulating data, you can use Firebase's built-in reports to analyze user behavior. For example:
    - Track user retention over time.
    - Measure user engagement with key app features (e.g., profile creation, messaging).
    - Look at user behavior across different language goals, regions, and proficiency levels.
  
  **Further Customization**:
  - You can also set up **Custom Audiences** in Firebase Analytics to track specific user segments. For example, users who created profiles with specific language goals or proficiency levels.

*/
import FirebaseAnalytics

class AnalyticsService {
    static let shared = AnalyticsService()
    
    // Track profile creation
    func trackProfileCreation(userId: String, region: String, language: String) {
        Analytics.logEvent("profile_creation", parameters: [
            "user_id": userId,
            "region": region,
            "language": language
        ])
    }

    // Track language goals set by the user
    func trackLanguageGoals(userId: String, goals: String, proficiency: String) {
        Analytics.logEvent("set_language_goals", parameters: [
            "user_id": userId,
            "goals": goals,
            "proficiency_level": proficiency
        ])
    }
    
    // Track message sent by the user
    func trackMessageSent(userId: String, penpalId: String) {
        Analytics.logEvent("message_sent", parameters: [
            "user_id": userId,
            "penpal_id": penpalId
        ])
    }

    // Track penpal connection
    func trackPenpalConnection(userId: String, penpalId: String) {
        Analytics.logEvent("penpal_connection", parameters: [
            "user_id": userId,
            "penpal_id": penpalId
        ])
    }
}
