//
//  AuthManager.swift
//  Penpal
//
//  Created by Austin William Tucker on 12/2/24.
//

import FirebaseAuth
import os

enum AuthError: Error {
    case secondFactorRequired
    case unknown
}

func debugLog(_ message: String) {
    #if DEBUG
    print(message)
    #endif
}


class AuthManager: ObservableObject {
    static let shared = AuthManager()
    var current2FAResolver: MultiFactorResolver?
    private let authLogger = Logger(subsystem: "com.penpal.auth", category: "AuthMAnager")

    @Published var requires2FA: Bool = false

    @Published var isAuthenticated: Bool = false
    @Published var userId: String?
    
    
    // MARK: - Log in with email and password
    func login(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // Basic sanity checks
        guard !email.isEmpty else {
            let error = NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Email must not be empty."])
            LoggerService.shared.log(.error, "❌ Login failed: Email must not be empty.", category: LogCategory.auth)
            completion(.failure(error))
            return
        }
        guard !password.isEmpty else {
            let error = NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Password must not be empty."])
            LoggerService.shared.log(.error, "❌ Login failed: Password must not be empty.", category: LogCategory.auth)
            completion(.failure(error))
            return
        }
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            // Check if 2FA is required
            if let error = error as NSError?, error.code == AuthErrorCode.secondFactorRequired.rawValue {
                guard let resolver = error.userInfo[AuthErrorUserInfoMultiFactorResolverKey] as? MultiFactorResolver else {
                    completion(.failure(error))
                    return
                }

                // ✅ Store the resolver so the UI can later call `resolve2FASignIn`
                self?.current2FAResolver = resolver
                self?.requires2FA = true

                // ✅ Notify your UI to prompt for the 2FA code (e.g. via published flag, delegate, etc.)
                LoggerService.shared.log(.warning, "⚠️ 2FA required. Prompt user to enter SMS code.", category: LogCategory.auth)
                completion(.failure(NSError(domain: "Auth", code: 2, userInfo: [NSLocalizedDescriptionKey: "2FA required."])))
                return
            }

            // Handle other login errors
            if let error = error {
                LoggerService.shared.log(.error, "❌ Failed to login: \(error.localizedDescription)", category: LogCategory.auth)
                completion(.failure(error))
                return
            }

            // ✅ Login success, no 2FA required
            // ✅ wrap in main thread
            DispatchQueue.main.async {
                self?.userId = result?.user.uid
                self?.isAuthenticated = true
                completion(.success(()))
                // NOTE: - don't log optionals otherwise it'll come up as Optional("abc123")
                if let userId = self?.userId {
                    LoggerService.shared.log(.info, "✅ Login successful with userId: \(userId)", category: LogCategory.auth, privacy: .private)
                } else {
                    LoggerService.shared.log(.warning, "⚠️ Login succeeded but userId was nil", category: LogCategory.auth)
                }

            }
        }
    }
    func cancel2FAFlow() {
        current2FAResolver = nil
        requires2FA = false
        LoggerService.shared.log(.info, "CANCELLED 2FA Flow", category: LogCategory.auth)
    }


    // MARK: - Log out the user
    func logout() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            do {
                try Auth.auth().signOut()
                self.isAuthenticated = false
                self.userId = nil
                self.current2FAResolver = nil
                LoggerService.shared.log(.info, "✅ Logout successful", category: LogCategory.auth)
            } catch {
                LoggerService.shared.log(.error, "❌ Error logging out: \(error.localizedDescription)", category: LogCategory.auth)
            }
        }
    }



    
    // MARK: - sendEmailVerification
    static func sendEmailVerification(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            let error = NSError(domain: LogCategory.auth, code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in."])
            LoggerService.shared.log(.error, "❌ Send email verification failed: User not logged in.", category: LogCategory.auth)
            completion(.failure(error))
            return
        }

        user.sendEmailVerification { error in
            if let error = error {
                LoggerService.shared.log(.error, "❌ Error sending email verification: \(error.localizedDescription)", category: LogCategory.auth)
                completion(.failure(error))
            } else {
                LoggerService.shared.log(.info, "✅ Email verification sent successfully.", category: LogCategory.auth)
                completion(.success(()))
            }
        }
    }



    // MARK: - Check current authentication status
    func checkAuthStatus() {
        DispatchQueue.main.async {
            if let user = Auth.auth().currentUser {
                self.isAuthenticated = true
                self.userId = user.uid
                LoggerService.shared.log(.info, "✅ User is authenticated with UID: \(user.uid)", category: LogCategory.auth, privacy: .private)
            } else {
                self.isAuthenticated = false
                self.userId = nil
                LoggerService.shared.log(.warning, "⚠️ No user is currently authenticated.", category: LogCategory.auth)
            }
        }
    }

    
    // MARK: - Enroll Phone for 2FA
    func enroll2FA(phoneNumber: String, completion: @escaping (String?, Error?) -> Void) {
        LoggerService.shared.log(.info, "Starting 2FA phone enrollment for number: \(phoneNumber)", category: LogCategory.auth)

        guard let user = Auth.auth().currentUser else {
            let error = NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in."])
            LoggerService.shared.log(.error, "❌ Failed 2FA enrollment: No authenticated user.", category: LogCategory.auth)
            completion(nil, error)
            return
        }

        LoggerService.shared.log(.info, "✅ Authenticated user found: \(user.uid). Requesting phone verification...", category: LogCategory.auth)

        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
            DispatchQueue.main.async {
                if let error = error {
                    LoggerService.shared.log(.error, "❌ Failed to send verification code: \(error.localizedDescription)", category: LogCategory.auth)
                    completion(nil, error)
                } else if let verificationID = verificationID {
                    LoggerService.shared.log(.info, "Verification code sent. Verification ID: \(verificationID)", category: LogCategory.auth)
                    completion(verificationID, nil)
                } else {
                    LoggerService.shared.log(.warning, "⚠️ Unexpected: No error and no verification ID returned.", category: "Auth")
                    completion(nil, NSError(domain: "Auth", code: 500, userInfo: [NSLocalizedDescriptionKey: "Unexpected error during 2FA enrollment."]))
                }
            }
        }
    }


    // MARK: - Confirm Phone Verification Code for 2FA
    func confirm2FA(verificationID: String, code: String, completion: @escaping (Error?) -> Void) {
        LoggerService.shared.log(.info, "Attempting to confirm 2FA with verification ID: \(verificationID)", category: LogCategory.auth, privacy: .private)
        LoggerService.shared.log(.info, "Attempting to confirm 2FA with verification code: \(code)", category: LogCategory.auth) // Careful with logging codes publicly

        guard let user = Auth.auth().currentUser else {
            let error = NSError(domain: LogCategory.auth, code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in."])
            LoggerService.shared.log(.error, "❌ 2FA confirmation failed: No authenticated user.", category: LogCategory.auth)
            completion(error)
            return
        }

        LoggerService.shared.log(.info, "✅ Authenticated user found: \(user.uid)", category: LogCategory.auth, privacy: .private)
        LoggerService.shared.log(.info, "Creating phone credential for 2FA enrollment...", category: LogCategory.auth)

        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: code)
        let assertion = PhoneMultiFactorGenerator.assertion(with: credential)

        LoggerService.shared.log(.info, "Enrolling phone credential for 2FA...", category: LogCategory.auth)

        user.multiFactor.enroll(with: assertion, displayName: "Phone") { error in
            DispatchQueue.main.async {
                if let error = error {
                    LoggerService.shared.log(.error, "❌ Failed to enroll phone for 2FA: \(error.localizedDescription)", category: LogCategory.auth)
                    completion(error)
                } else {
                    LoggerService.shared.log(.info, "✅ Successfully enrolled phone for 2FA.", category: LogCategory.auth)
                    completion(nil)
                }
            }
        }
    }


    
    // MARK: - Resolve Sign-In with 2FA Code
    func resolve2FASignIn(resolver: MultiFactorResolver, smsCode: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let hint = resolver.hints.first as? PhoneMultiFactorInfo else {
            let error = NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "No second factor found."])
            log(.error, "❌ Failed to resolve 2FA: No second factor found.", category: LogCategory.auth)
            completion(.failure(error))
            return
        }

        LoggerService.shared.log(.info, "Resolving 2FA sign-in for phone factor: \(hint.displayName ?? "Unnamed")", category: LogCategory.auth, privacy: .private)

        // Use the resolver’s session to create credential
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: resolver.session.verificationID,
            verificationCode: smsCode
        )
        let assertion = PhoneMultiFactorGenerator.assertion(with: credential)

        resolver.resolveSignIn(with: assertion) { [weak self] authResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    LoggerService.shared.log(.error, "❌ Failed to resolve 2FA sign-in: \(error.localizedDescription)", category: LogCategory.auth)                    completion(.failure(error))
                } else if let user = authResult?.user {
                    self?.userId = user.uid
                    self?.isAuthenticated = true
                    self?.requires2FA = false
                    self?.current2FAResolver = nil

                    LoggerService.shared.log(.info, "✅ 2FA sign-in successful for userId: \(user.uid)", category: LogCategory.auth, privacy: .private)                    completion(.success(()))
                } else {
                    let unknownError = NSError(domain: "Auth", code: 500, userInfo: [NSLocalizedDescriptionKey: "Unknown authentication error."])
                    LoggerService.shared.log(.warning, "⚠️ 2FA sign-in returned no error and no user.", category: LogCategory.auth)             completion(.failure(unknownError))
                }
            }
        }
    }


    
    // TODO: - Add support for TOTP (Time-based One-Time Password) 2FA
    // Firebase Auth supports TOTP as a second factor.
    // This requires enabling TOTP in Firebase Console and using `TOTPEnrollment` and `TOTPAssertion`.
    // Design UI to show QR code and verify TOTP code.
    
    // MARK: - Enroll TOTP 2FA (Placeholder for future support)
    func enrollTOTP(completion: @escaping (String?, Error?) -> Void) {
        // TODO: Implement enrollment using TOTPMultiFactorGenerator
        // This should return a shared secret or QR code to display to user
        LoggerService.shared.log(.info, "Attempting to enroll TOTP 2FA (not yet supported)", category: LogCategory.auth)
        completion(nil, NSError(domain: "Auth", code: 501, userInfo: [NSLocalizedDescriptionKey: "TOTP not yet supported."]))
    }

    // MARK: - Confirm TOTP Code (Placeholder for future support)
    func confirmTOTPEnrollment(secret: String, verificationCode: String, completion: @escaping (Error?) -> Void) {
        // TODO: Verify TOTP code entered by user and enroll it
        LoggerService.shared.log(.info, "Attempting to confirm TOTP 2FA (not yet supported)", category: LogCategory.auth)
        completion(NSError(domain: "Auth", code: 501, userInfo: [NSLocalizedDescriptionKey: "TOTP not yet supported."]))
    }

    // MARK: - Resolve Sign-In with TOTP (Placeholder for future support)
    func resolveTOTP2FASignIn(resolver: MultiFactorResolver, code: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // TODO: Implement resolving sign-in with TOTP assertion
        LoggerService.shared.log(.info, "Attempting to resolve TOTP 2FA sign-in (not yet supported)", category: LogCategory.auth)
        completion(.failure(NSError(domain: "Auth", code: 501, userInfo: [NSLocalizedDescriptionKey: "TOTP 2FA sign-in not yet supported."])))
    }
    
    // TODO: - Managing multiple enrolled second factors per user
    // Add support to list, remove, or rename 2FA factors (e.g., backup phone numbers or TOTP)

    // MARK: - List all enrolled second factors
    func listEnrolledSecondFactors(completion: @escaping ([MultiFactorInfo]?, Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            LoggerService.shared.log(.warning, "⚠️ Tried to list second factors but no user is logged in.", category: LogCategory.auth)
            completion(nil, NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in."]))
            return
        }
        LoggerService.shared.log(.info, "✅ Listing enrolled second factors for userId: \(user.uid)", category: LogCategory.auth, privacy: .private)
        let factors = user.multiFactor.enrolledFactors
        completion(factors, nil)
    }

    // MARK: - TODO: Remove a second factor (e.g., a lost phone number)
    // Firebase currently only allows removal via Admin SDK or using the REST API for some factors.
    // You may need to direct users to support flow or re-authenticate and use Admin logic.
    func removeSecondFactor(factorUID: String, completion: @escaping (Error?) -> Void) {
        // Placeholder: Firebase iOS SDK doesn't support removal via client directly
        // Implement via callable Cloud Function or Admin SDK
        LoggerService.shared.log(.warning, "⚠️ Attempted to remove second factor (not supported in client SDK)", category: LogCategory.auth)
        completion(NSError(domain: "Auth", code: 403, userInfo: [NSLocalizedDescriptionKey: "Removing 2FA factors not supported in client SDK."]))
    }
    
    
    // MARK: - Sign up with email and password
    func signUp(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // Basic client-side validation
        guard !email.isEmpty else {
            let error = NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Email must not be empty."])
            LoggerService.shared.log(.error, "❌ SignUp failed: Email must not be empty.", category: LogCategory.auth)
            completion(.failure(error))
            return
        }
        guard !password.isEmpty else {
            let error = NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Password must not be empty."])
            LoggerService.shared.log(.error, "❌ SignUp failed: Password must not be empty.", category: LogCategory.auth)
            completion(.failure(error))
            return
        }
        // You could add your password strength validation here if you want

        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    LoggerService.shared.log(.error, "❌ SignUp failed: \(error.localizedDescription)", category: LogCategory.auth)
                    completion(.failure(error))
                    return
                }
                guard let user = authResult?.user else {
                    let error = NSError(domain: "Auth", code: 500, userInfo: [NSLocalizedDescriptionKey: "User creation failed."])
                    LoggerService.shared.log(.error, "❌ SignUp failed: User creation failed.", category: LogCategory.auth)
                    completion(.failure(error))
                    return
                }

                // Send email verification
                user.sendEmailVerification { error in
                    if let error = error {
                        LoggerService.shared.log(.error, "❌ Email verification send failed: \(error.localizedDescription)", category: LogCategory.auth)
                        completion(.failure(error))
                        return
                    }

                    // Signup success - user created and verification email sent
                    self?.userId = user.uid
                    self?.isAuthenticated = false // user must verify email before full auth
                    LoggerService.shared.log(.info, "✅ SignUp successful. Verification email sent to \(email)", category: LogCategory.auth, privacy: .private)
                    completion(.success(()))
                }
            }
        }
    }

    
    // MARK: - Send Password Reset Email
    func sendPasswordReset(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // Basic validation
        guard !email.isEmpty else {
            let error = NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Email must not be empty."])
            LoggerService.shared.log(.error, "❌ Password reset failed: Email must not be empty.", category: LogCategory.auth)
            completion(.failure(error))
            return
        }

        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    LoggerService.shared.log(.error, "❌ Password reset error: \(error.localizedDescription)", category: LogCategory.auth)
                    completion(.failure(error))
                } else {
                    LoggerService.shared.log(.info, "✅ Password reset email sent to \(email)", category: LogCategory.auth, privacy: .private)
                    completion(.success(()))
                }
            }
        }
    }


}

enum SecondFactorMethod {
    case sms
    case totp
}
