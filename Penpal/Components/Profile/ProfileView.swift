//
//  ProfileView.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//

import SwiftUI

/*
 Things To Incorporate
 
 Back Button
 
 Ties to the amount of hobbies, select as well
 
 As well as dropdown for language proficiency
 
 These should also be within the welcome page
 What Are You Looking For:
 
 Higher Level, same level
 
 Page for if your open to being selected by people wanting to communicate with you for practice or practice with you out of your target language
 
 Submit Profile - ties to create profile on Firebase
 
 
 
 */

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel() // Initialize the ViewModel
    let userId: String // Pass in the userId to fetch the profile
    @Binding var selectedTab: Tab

    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                // Show a loading indicator
                ProgressView("Loading Profile...")
                    .padding()
            } else if let errorMessage = viewModel.errorMessage {
                // Show an error message
                VStack {
                    Text("Error")
                        .font(.headline)
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button(action: {
                        viewModel.fetchUserProfile(userId: userId)
                    }) {
                        Text("Retry")
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
                .padding()
            } else if let profile = viewModel.profile {
                // Show profile details
                VStack {
                    if let imageURL = URL(string: profile.profileImageURL) {
                        AsyncImage(url: imageURL) { image in
                            image.resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .padding()
                    }
                    
                    Text("\(profile.firstName) \(profile.lastName)")
                        .font(.title)
                        .padding(.bottom, 2)
                    
                    Text("\(profile.region), \(profile.country)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Divider()
                        .padding(.vertical, 10)
                    
                    // List of hobbies
                    VStack(alignment: .leading) {
                        Text("Hobbies:")
                            .font(.headline)
                        ForEach(profile.hobbies, id: \.self) { hobby in
                            Text("• \(hobby.name)")
                                .font(.body)
                        }
                    }
                    .padding(.bottom, 10)
                    
                    // List of goals
                    VStack(alignment: .leading) {
                        Text("Language Goals:")
                            .font(.headline)
                        ForEach(profile.goals, id: \.self) { goal in
                            Text("• \(goal)")
                                .font(.body)
                        }
                    }
                    
                    Spacer()
                    
                    // Button to edit profile
                    Button(action: {
                        // Navigate to edit profile screen
                    }) {
                        Text("Edit Profile")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.top, 20)
                }
                .padding()
            } else {
                // If no profile is loaded, fetch it
                Text("No profile found")
                    .font(.headline)
                    .foregroundColor(.gray)
                Button(action: {
                    viewModel.fetchUserProfile(userId: userId)
                }) {
                    Text("Retry")
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding(.top, 10)
            }
        }
        .padding()
        .onAppear {
            viewModel.fetchUserProfile(userId: userId)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(userId: "sampleUserId")
    }
}
