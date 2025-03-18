//
//  EditProfileView.swift
//  Penpal
//
//  Created by Austin William Tucker on 2/14/25.
//

/*
 This view allows users to edit their profile, including toggling notification preferences.
 It includes a custom toggle style (PinkToggleStyle) for a personalized UI.
 
 
 Possibly within Edit Profile Needs to Consider
 
 Preferences
 
 Settings
 
 
 */

import SwiftUI // Importing the SwiftUI framework for building the user interface


// MARK:  - I think a lot of this will be needed for the allow notificaitons section of the WelcomePageview
struct EditProfileView: View {
    
    // Binding to allow changes in this view to update the parent view's profile data
    @Binding var profile: Profile
    
    // States for managing toggle preferences (1h, 6h, 24h notifications)
    @State private var notify1h = true
    @State private var notify6h = false
    @State private var notify24h = false

    var body: some View {
        Form { // A container to organize settings in sections
            Section(header: Text("Notification Preferences")) { // Section for notification toggles
                // Toggle for 1-hour notification, styled with PinkToggleStyle
                Toggle("1 Hour Before", isOn: $notify1h)
                    .toggleStyle(PinkToggleStyle()) // Applying custom toggle style
                
                // Toggle for 6-hour notification, styled with PinkToggleStyle
                Toggle("6 Hours Before", isOn: $notify6h)
                    .toggleStyle(PinkToggleStyle())
                
                // Toggle for 24-hour notification, styled with PinkToggleStyle
                Toggle("24 Hours Before", isOn: $notify24h)
                    .toggleStyle(PinkToggleStyle())
            }
            .padding(.vertical, 10) // Adds vertical padding to the section
        }
        .navigationTitle("Edit Profile") // Title for the navigation bar
        .navigationBarTitleDisplayMode(.inline) // Keeps the navigation title inline with the back button
    }
}

// Custom toggle style that changes the bar color to pink when toggled on
struct PinkToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label // The text or label associated with the toggle
            
            Spacer() // Pushes the toggle to the right side
            
            // ZStack to create the toggle background and sliding circle
            ZStack {
                RoundedRectangle(cornerRadius: 16) // Background shape for the toggle
                    .fill(configuration.isOn ? Color.pink : Color.gray.opacity(0.3)) // Pink for "on," gray for "off"
                    .frame(width: 50, height: 30) // Size of the toggle background
                
                Circle() // The circle that slides inside the toggle
                    .fill(Color.white) // White color for the toggle circle
                    .frame(width: 24, height: 24) // Size of the toggle circle
                    .offset(x: configuration.isOn ? 10 : -10) // Moves the circle based on toggle state
                    .animation(.easeInOut, value: configuration.isOn) // Smooth animation when toggling
            }
            .onTapGesture {
                configuration.isOn.toggle() // Toggles the state when tapped
            }
        }
    }
}

// Preview structure to test and visualize the EditProfileView in Xcode
struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        // Providing a sample profile for preview purposes
        EditProfileView(profile: .constant(Profile(
            firstName: "Austin",
            lastName: "Tucker",
            email: "austin@example.com",
            hobbies: [],
            goals: []
        )))
    }
}
