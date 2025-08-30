//
//  AuthView.swift
//  Penpal
//
//  Created by Austin William Tucker on 8/23/25.
//

struct AuthFlow: View {
    enum Route { case welcome, login, signup }
    @State private var route: Route = .welcome

    var body: some View {
        NavigationStack {
            switch route {
            case .welcome:
                WelcomePage(
                    onLogin: { route = .login },
                    onSignup: { route = .signup }
                )
            case .login:
                LoginView(
                    onSignupTapped: { route = .signup },
                    onForgotTapped: { /* push Forgot */ }
                )
            case .signup:
                SignUpView(onHaveAccount: { route = .login })
            }
        }
    }
}
