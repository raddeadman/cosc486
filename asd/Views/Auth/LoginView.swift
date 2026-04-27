import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @FocusState private var isEmailFocused

    var body: some View {



        VStack(spacing: 24) {
            // App Logo/Icon
            Image(systemName: "shopping.bag")
                .font(.system(size: 50))
                .foregroundColor(.blue)
                .padding(.bottom, 8)

            Text("Open Market")
                .font(.largeTitle.bold())
                .foregroundColor(.primary)

            Text("Buy & Sell products locally")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 24)

            // Email Field
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .focused($isEmailFocused)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom, 16)

            // Password Field
            SecureField("Password", text: $password)
                .textContentType(.password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom, 24)

            // Login Button
            PrimaryButton(title: "Login", isLoading: authViewModel.isLoading) {
                withAnimation {
                    Task { @MainActor in
                        isEmailFocused = false
                authViewModel.login(email: email, password: password)
            }



            }
            }



            // Error Message
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)

                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }

            // Create Account Navigation
            HStack {
                Text("Don't have an account?")
                    .foregroundColor(.secondary)

                NavigationLink {
                    SignUpView()
                } label: {
                    Text("Sign Up")
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
        }

    }
}
        .padding(24)
        .background(Color(NSColor.textBackgroundColor))
    }
}
