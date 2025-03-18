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
    // Language options (You can replace with more languages)
    let languageOptions = ["English", "Spanish", "French", "German", "Chinese", "Japanese"]

    @State private var selectedFluentLanguage = "English"
    @State private var selectedLearningLanguage = "Spanish"

    var body: some View {
        VStack {
            if isSubmitting {
                ProgressView("Creating Profile...")
            } else {
                TabView(selection: $currentStep) {
                    
                    /*
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
                     */
                    
                    // MARK: - Step 1: Welcome Screen
                    VStack {
                        Text("Welcome to Penpal!")
                            .font(.custom("Nunito", size: 24))  // Use Nunito font with size 24
                            .fontWeight(.bold)  // Weight 700 (bold)
                            .lineSpacing(32.74)  // Line height (line spacing)
                            .frame(maxWidth: .infinity, alignment: .center)  // Center-align text
                            .padding()

                        Text("Start your language journey today.")
                            .font(.custom("Nunito", size: 16))  // Same font and size as above
                            .fontWeight(.regular)  // Bold weight
                            .lineSpacing(32.74)  // Same line height
                            .frame(maxWidth: .infinity, alignment: .center)  // Center-align text
                            .padding(.bottom)

                        
                        Button(action: { currentStep += 1 }) {
                            Text("Sign Up with Email")
                                .font(.custom("Nunito", size: 16)) // Font: Nunito, Size: 16px
                                .fontWeight(.bold) // Weight: 700
                                .foregroundColor(Color(hex: "#EB5C6E")) // Text color: #EB5C6E
                                .frame(maxWidth: .infinity, minHeight: 50) // Width: Fill (358px), Height: Fixed (50px)
                                .lineSpacing(21.82) // Line height: 21.82px
                                .padding(.vertical, 16) // Padding: Top 16px, Bottom 16px
                                .background(Color.white) // Button color: White (#FFFFFF)
                                .cornerRadius(25) // Radius: 25px
                        }
                        .padding(.bottom)

                        // MARK: - TODO Add Logic For Google Sign In
                        Button(action: { /* Google Sign-In Logic */ }) {
                            HStack {
                                Image("google_logo") // Add Google logo from assets
                                    .resizable()
                                    .frame(width: 24, height: 24) // Adjust logo size as needed
                                    .padding(.leading, 16) // Align logo properly
                                
                                Text("Continue with Google")
                                    .font(.custom("Nunito", size: 16)) // Font: Nunito, Size: 16px
                                    .fontWeight(.bold) // Weight: 700
                                    .foregroundColor(Color(hex: "#636363")) // Text color: #636363
                                    .frame(maxWidth: .infinity, minHeight: 50) // Width: Fill (358px), Height: Fixed (50px)
                                    .lineSpacing(21.82) // Line height: 21.82px
                                    .padding(.trailing, 16) // Spacing for balance
                            }
                            .padding(.vertical, 16) // Padding: Top 16px, Bottom 16px
                            .background(Color.white) // Button color: White (#FFFFFF)
                            .cornerRadius(25) // Radius: 25px
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.gray, lineWidth: 1) // Gray outline
                            )
                        }
                        .padding(.bottom)

                        // MARK: - TODO Add Logic For LogIn
                        Button(action: { /* Navigate to Login */ }) {
                            Text("Already have an account? Log in")
                                .foregroundColor(.blue)
                        }
                        .padding(.top)
                    }
                    .tag(0)
                    .padding()
                    
                    // MARK: - Step 2: Email Entry
                    VStack {
                        Text("What's your email?")
                            .font(.custom("Nunito", size: 24).weight(.bold))
                            .foregroundColor(Color(hex: "#000000")) // Pure black
                            .frame(width: 216, height: 33, alignment: .leading)
                            .lineSpacing(32.74 - 24) // Adjusts line height
                        
                        TextField("Enter your email", text: $email)
                            .font(.custom("Nunito", size: 16).weight(.bold))
                            .frame(width: 42, height: 22, alignment: .leading)
                            .lineSpacing(21.82 - 16) // Adjusts line height
                            .textFieldStyle(PlainTextFieldStyle()) // Removes default styling
                        // Grey line underneath
                        Rectangle()
                            .fill(Color.gray.opacity(0.5)) // Light grey color
                            .frame(height: 1) // Thin underline
                    
                        NavigationButton(text: "Next", action: { currentStep += 1 })
                    }
                    .tag(1)
                    .padding()
                    
                    // MARK: - Step 3: Email Verification
                    VStack {
                        Text("Verify your email")
                            .font(.custom("Nunito", size: 24))
                            .fontWeight(.bold)
                            .frame(width: 189, height: 33, alignment: .leading)
                            .multilineTextAlignment(.leading)
                        
                        Text("We sent a 4-digit code to \(email). Enter it below.")
                            .font(.custom("Nunito", size: 16))
                            .foregroundColor(Color(hex: "#636363")) // Grey
                            .frame(width: 283, height: 44, alignment: .leading)
                            .multilineTextAlignment(.leading)
                        
                        TextField("Enter code", text: $verificationCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                            .keyboardType(.numberPad)
                        
                        Button(action: { /* Resend email logic */ }) {
                            Text("Didn't receive a code? Resend")
                                .foregroundColor(.blue)
                        }
                        .padding(.bottom)
                        
                        NavigationButton(text: "Verify", action: { currentStep += 1 })
                    }
                    .tag(2)
                    .padding()
                    
                    // MARK: - Step 4: Name Entry
                    VStack {
                        Text("What's your name?")
                            .font(.custom("Nunito", size: 24))  // Use the Nunito font with size 24
                            .fontWeight(.bold)  // Bold weight
                            .lineSpacing(32.74)  // Line height (or line spacing in SwiftUI)
                            .padding(.horizontal, 16)  // Optional padding for horizontal spacing
                            .frame(width: 216, height: 33, alignment: .leading)  // Custom width and height
                            .foregroundColor(.black)  // Set text color to black if needed

                        
                        Text("This will appear on your Penpal profile.")
                            .font(.custom("Nunito", size: 16))  // Use the Nunito font with size 16
                            .fontWeight(.regular)  // Weight 400 is equivalent to regular
                            .lineSpacing(21.82)  // Line height (or line spacing in SwiftUI)
                            .padding(.bottom)  // Add bottom padding
                            .frame(width: 278, height: 22, alignment: .leading)  // Custom width and height
                            .foregroundColor(.black)  // Set text color to black

                        
                        TextField("First Name", text: $firstName)
                            .font(.custom("Nunito", size: 16))  // Use Nunito font with size 16
                            .fontWeight(.bold)  // Weight 700 corresponds to bold
                            .lineSpacing(21.82)  // Line height (line spacing in SwiftUI)
                            .frame(width: 77, height: 22, alignment: .leading)  // Custom width and height
                            .textFieldStyle(RoundedBorderTextFieldStyle())  // Apply rounded border style to text field
                            .padding()  // Padding around the text field
                        // Grey line underneath
                        Rectangle()
                            .fill(Color.gray.opacity(0.5)) // Light grey color
                            .frame(height: 1) // Thin underline
                        
                        TextField("Last Name", text: $lastName)
                            .font(.custom("Nunito", size: 16))  // Use Nunito font with size 16
                            .fontWeight(.bold)  // Weight 700 corresponds to bold
                            .lineSpacing(21.82)  // Line height (line spacing in SwiftUI)
                            .frame(width: 77, height: 22, alignment: .leading)  // Custom width and height
                            .textFieldStyle(RoundedBorderTextFieldStyle())  // Apply rounded border style to text field
                            .padding()  // Padding around the text field
                        // Grey line underneath
                        Rectangle()
                            .fill(Color.gray.opacity(0.5)) // Light grey color
                            .frame(height: 1) // Thin underline

                        
                        NavigationButton(text: "Next", action: { currentStep += 1 })
                    }
                    .tag(3)
                    .padding()
                    
                    // MARK: - Step 5: Profile Picture
                    VStack {
                        Text("Your Profile Picture")
                            .font(.custom("Nunito"),size: 24) // Use the Nunito font with size 24
                            .fontWeight(.bold) // Bold weight
                            .lineSpacing(32.74) // Line height (or line spacing in SwiftUI)
                            .padding(.horizontal,16) // Optional padding for horizontal spacing
                            .frame(width: 216,height: 33, alignment: .leading)  // Custom width and height
                            .foregroundColor(.black)  // Set text color to black if needed

                        Text("Let's put a face to your name")
                            .font(.custom("Nunito", size: 16))  // Use the Nunito font with size 16
                            .fontWeight(.regular)  // Weight 400 is equivalent to regular
                            .lineSpacing(21.82)  // Line height (or line spacing in SwiftUI)
                            .padding(.bottom)  // Add bottom padding
                            .frame(width: 278, height: 22, alignment: .leading)  // Custom width and height
                            .foregroundColor(.black)  // Set text color to black

                        
                        if let image = profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                                .clipShape(Circle())
                                .padding()
                        } else {
                            // MARK: TODO - ADD IMAGE PICKER THING
                            Button(action: { /* Open Image Picker */ }) {
                                Text("Upload Profile Picture")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .padding()
                        }
                        
                        NavigationButton(text: "Next", action: { currentStep += 1 })
                    }
                    .tag(4)
                    .padding()
                    
                    // MARK: - Step 6: Allow Notifications
                    VStack {
                        Text("Allow email notifications?")
                            .font(.custom("Nunito", size: 24))  // Use the Nunito font with size 24
                            .fontWeight(.bold)  // Bold weight
                            .lineSpacing(32.74)  // Line height (or line spacing in SwiftUI)
                            .padding(.horizontal, 16)  // Optional padding for horizontal spacing
                            .frame(width: 216, height: 33, alignment: .leading)  // Custom width and height
                            .foregroundColor(.black)  // Set text color to black if needed

                        // MARK: - TODO ADD Receive Updates and Receive Messages
                        /*
                         One is for one hour before the meeting
                         Two is for 6 hours before
                         Three is for 24 hours before a session
                         
                         Update on new penpals received
                         */
                        Toggle("Receive updates and messages via email", isOn: $allowNotifications)
                            .padding()
                        
                        
                    
                    }
                    .tag(5)
                    .padding()
            
                    
                    // MARK: - Step 7: Region
                    VStack {
                        Text("Where are you from?")
                            .font(.custom("Nunito", size: 24))  // Use the Nunito font with size 24
                            .fontWeight(.bold)  // Bold weight
                            .lineSpacing(32.74)  // Line height (or line spacing in SwiftUI)
                            .padding(.horizontal, 16)  // Optional padding for horizontal spacing
                            .frame(width: 216, height: 33, alignment: .leading)  // Custom width and height
                            .foregroundColor(.black)  // Set text color to black if needed
                        TextField("Region (e.g., California)", text: $profileViewModel.region)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                        TextField("Country (e.g., USA)", text: $profileViewModel.country)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                        
                        NavigationButton(text: "Next", action: nextStep)
                    }
                    .tag(6)
                    .padding()
                    
                    // MARK: - Step 8: Hobbies
                    VStack {
                        Text("What are your hobbies?")
                            .font(.custom("Nunito", size: 24))  // Use the Nunito font with size 24
                            .fontWeight(.bold)  // Bold weight
                            .lineSpacing(32.74)  // Line height (or line spacing in SwiftUI)
                            .padding(.horizontal, 16)  // Optional padding for horizontal spacing
                            .frame(width: 216, height: 33, alignment: .leading)  // Custom width and height
                            .foregroundColor(.black)  // Set text color to black if needed
                        
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
                    .tag(7)
                    .padding()
                    
                    // MARK: - Step 9: Selecting Your Language
                    VStack(alignment: .leading, spacing: 20) {
                        // Section Title
                        Text("Language Info")
                            .font(.custom("Nunito", size: 24).weight(.bold))

                        Text("This will appear on your Penpal profile.")
                            .font(.custom("Nunito", size: 16))
                            .foregroundColor(.gray)
                        
                        // Fluent Language
                        Text("What language(s) are you fluent in?")
                            .font(.custom("Nunito", size: 16).weight(.bold))
                        // Dropdown for Fluent Languages
                        Menu {
                            ForEach(languageOptions, id: \.self) { language in
                                Button(action: { selectedFluentLanguage = language }) {
                                    Text(language)
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedFluentLanguage)
                                    .font(.custom("Nunito", size: 16))
                                    .foregroundColor(.black)
                                Spacer()
                                Image(systemName: "chevron.down") // Dropdown icon
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5), lineWidth: 1)) // Border
                        }

                        // Grey underline
                        Rectangle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(height: 1)

                        // MARK: - What Learning Language User Wants
                        Text("What language(s) are you learning?")
                            .font(.custom("Nunito", size: 16).weight(.bold))

                        // Dropdown for Learning Languages
                        Menu {
                            ForEach(languageOptions, id: \.self) { language in
                                Button(action: { selectedLearningLanguage = language }) {
                                    Text(language)
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedLearningLanguage)
                                    .font(.custom("Nunito", size: 16))
                                    .foregroundColor(.black)
                                Spacer()
                                Image(systemName: "chevron.down") // Dropdown icon
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5), lineWidth: 1)) // Border
                        }

                        // Grey underline
                        Rectangle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(height: 1)
                    }
                    .tag(8)
                    .padding()

                    
                    // MARK: - Step 10: Goals
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
                    .tag(9)
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

func sendVerificationCode() {
        isVerifying = true
        AuthManager.sendEmailVerification(email: email) { success in
            if success {
                // Navigate to verification screen
            } else {
                // Show error message
            }
        }
    }

// Used for previewing the page
/*
struct WelcomePage_Previews: PreviewProvider {
    static var previews: some View {
        WelcomePage()
    }
}/*
