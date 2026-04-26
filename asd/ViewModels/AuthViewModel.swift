import Foundation
import Combine
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

final class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoggedIn = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authService = AuthService()

    func login(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        authService.login(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let user):
                    self?.currentUser = user
                    self?.isLoggedIn = true
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func signUp(name: String, email: String, password: String) {
        isLoading = true
        errorMessage = nil
        authService.signUp(name: name, email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let user):
                    self?.currentUser = user
                    self?.isLoggedIn = true
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func logout() {
        authService.logout()
        currentUser = nil
        isLoggedIn = false
    }
}
