//
//  WelcomePage.swift
//  Penpal
//
//  Created by Austin William Tucker on 12/18/24.
//



/*
 Page  
 What Are You Looking For:
 
 Higher Level, same level
 
 Page for if your open to being selected by people wanting to communicate with you for practice or practice with you out of your target language
 
 Submit Profile - ties to create profile on Firebase
 
 
 */
import SwiftUI

struct WelcomePage: View {
    @ObservedObject var profileViewModel: ProfileViewModel
    @State private var currentStep = 0
    @State private var isSubmitting = false

    var body: some View {
        VStack {
            if isSubmitting {
                ProgressView("Creating Profile...")
            } else {
                TabView(selection: $currentStep) {
                    
                    // Step 1: Name
                    VStack {
                        Text("Welcome!")
                            .font(.largeTitle)
                            .bold()
                            .padding(.bottom)
                        Text("Let's start by getting your name.")
                        
                        TextField("First Name", text: $profileViewModel.firstName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                        TextField("Last Name", text: $profileViewModel.lastName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                        
                        NavigationButton(text: "Next", action: nextStep)
                    }
                    .tag(0)
                    .padding()
                    
                    // Step 2: Region
                    VStack {
                        Text("Where are you from?")
                            .font(.title2)
                            .bold()
                            .padding(.bottom)
                        TextField("Region (e.g., California)", text: $profileViewModel.region)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                        TextField("Country (e.g., USA)", text: $profileViewModel.country)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                        
                        NavigationButton(text: "Next", action: nextStep)
                    }
                    .tag(1)
                    .padding()
                    
                    // Step 3: Hobbies
                    VStack {
                        Text("What are your hobbies?")
                            .font(.title2)
                            .bold()
                            .padding(.bottom)
                        
                        List {
                            ForEach(ProfileViewModel.hobbyOptions, id: \.self) { hobby in
                                HStack {
                                    Text(hobby)
                                    Spacer()
                                    if profileViewModel.hobbies.contains(hobby) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    profileViewModel.toggleHobby(hobby)
                                }
                            }
                        }
                        
                        NavigationButton(text: "Next", action: nextStep)
                    }
                    .tag(2)
                    .padding()
                    
                    // Step 4: Goals
                    VStack {
                        Text("What are your language learning goals?")
                            .font(.title2)
                            .bold()
                            .padding(.bottom)
                        TextField("Enter your goals (comma-separated)", text: Binding(
                            get: { profileViewModel.goals.joined(separator: ", ") },
                            set: { profileViewModel.goals = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        
                        NavigationButton(text: "Finish", action: submitProfile)
                    }
                    .tag(3)
                    .padding()
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }
        }
        .padding()
        .alert(item: $profileViewModel.errorMessage) { error in
            Alert(title: Text("Error"), message: Text(error), dismissButton: .default(Text("OK")))
        }
    }
    
    private func nextStep() {
        if currentStep < 3 {
            currentStep += 1
        }
    }

    private func submitProfile() {
        isSubmitting = true
        profileViewModel.createUserProfile { result in
            DispatchQueue.main.async {
                isSubmitting = false
                switch result {
                case .success:
                    print("Profile created successfully!")
                    // Navigate to the main app
                case .failure(let error):
                    profileViewModel.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct NavigationButton: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding()
    }
}

// Used for previewing the page
/*
struct WelcomePage_Previews: PreviewProvider {
    static var previews: some View {
        WelcomePage()
    }
}/*
