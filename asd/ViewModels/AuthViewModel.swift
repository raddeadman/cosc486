import Foundation
import Combine
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif
import FirebaseFirestore

final class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoggedIn = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var userDisplayName: String?

    private let authService = AuthService()
    private var authStateHandle: AnyCancellable?

    init() {
        setupAuthListener()
    }

    // MARK: - Authentication Methods

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
                    self?.userDisplayName = user.name.isEmpty ? "Guest" : user.name
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
                    self?.userDisplayName = user.name.isEmpty ? "Guest" : user.name
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
        userDisplayName = nil
    }

    // MARK: - Auth State Listener

    private func setupAuthListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                if let user = user {
                    // User is signed in
                    Task.detached { [weak self] in
                        guard let self = self else { return }

                        do {
                            let userProfile = try await self.authService.fetchUserProfile(uid: user.uid)
                            self.currentUser = userProfile
                            self.isLoggedIn = true
                            self.userDisplayName = userProfile.name.isEmpty ? "Guest" : userProfile.name
                        } catch {
                            print("Failed to fetch user profile: \(error)")
                            self.currentUser = nil
                            self.isLoggedIn = false
                        }
                    }
                } else {
                    // User is signed out
                    self?.currentUser = nil
                    self?.isLoggedIn = false
                    self?.userDisplayName = nil
                }
            }
        }
    }

    func refreshUserProfile() {
        Task.detached { [weak self] in
            guard let self = self, let currentUser = self.currentUser else { return }

            do {
                let userProfile = try await self.authService.fetchUserProfile(uid: currentUser.id)
                DispatchQueue.main.async {
                    self.currentUser = userProfile
                }
            } catch {
                print("Failed to refresh user profile: \(error)")
            }
        }
    }
}

// MARK: - FirebaseAuth Error Handler
extension AuthService {
    private struct FirebaseAuthError: LocalizedError {
        var errorDescription: String?
    }
}

