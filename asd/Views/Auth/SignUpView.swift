import SwiftUI

struct SignUpView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    var body: some View {
        VStack(spacing: 12) {
            TextField("Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            SecureField("Confirm password", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            PrimaryButton(title: "Create account", isLoading: authViewModel.isLoading) {
                guard password == confirmPassword else {
                    authViewModel.errorMessage = "Passwords do not match."
                    return
                }
                authViewModel.signUp(name: name, email: email, password: password)
            }
        }
        .navigationTitle("Sign Up")
        .padding()
    }
}
