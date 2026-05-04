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
    private var authStateHandle: NSObjectProtocol?
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupAuthListener()
    }

    // MARK: - Authentication Methods

    func login(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        authService.login(email: email, password: password)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] user in
                    self?.currentUser = user
                    self?.isLoggedIn = true
                    self?.userDisplayName = user.name.isEmpty ? "Guest" : user.name
                }
            .store(in: &cancellables)
            }

    func signUp(name: String, email: String, password: String) {
        isLoading = true
        errorMessage = nil
        authService.signUp(name: name, email: email, password: password)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
        }
            } receiveValue: { [weak self] user in
                self?.currentUser = user
                    self?.isLoggedIn = true
                self?.userDisplayName = user.name.isEmpty ? "Guest" : user.name
                }
            .store(in: &cancellables)
            }

    func logout() {
        authService.logout()
            .sink { _ in
                // Handle completion if needed
            } receiveValue: { _ in
                // Logout successful
        }
            .store(in: &cancellables)
        currentUser = nil
        isLoggedIn = false
        userDisplayName = nil
    }

    // MARK: - Fetch Current User (replaces anonymous sign-in)

    func fetchCurrentUser() async {
        let auth = Auth.auth()
                        do {
            // Check if there's an existing session
            if auth.currentUser != nil {
                // User is already signed in, fetch their profile
                for await userProfile in authService.fetchUserProfile(uid: auth.currentUser!.uid).values {
                DispatchQueue.main.async { [weak self] in
                    self?.currentUser = userProfile
                    self?.isLoggedIn = true
                    self?.userDisplayName = userProfile.name.isEmpty ? "Guest" : userProfile.name
                            }
                    break // We only need the first value
                }
            } else {
                // No session, try to sign in anonymously (for testing) or require email login
                // For production, you might want to redirect to login view instead
                print("No active session. User needs to log in.")
        }
            } catch {
            print("Failed to fetch current user: $error")
}
        }

    // MARK: - Auth State Listener

    private func setupAuthListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            // Always dispatch to main thread for @Published updates
                DispatchQueue.main.async {
                if let user = user {
                    // User is signed in - fetch profile on background task, then update on main
                    Task.detached { [weak self] in
                        guard let self = self else { return }

                        do {
                            for await userProfile in self.authService.fetchUserProfile(uid: user.uid).values {
                            // Update @Published properties from the main queue
                            DispatchQueue.main.async {
                                self.currentUser = userProfile
                                self.isLoggedIn = true
                                self.userDisplayName = userProfile.name.isEmpty ? "Guest" : userProfile.name
            }
                break // We only need the first value
            }
                        } catch {
                            print("Failed to fetch user profile: $error")
                            DispatchQueue.main.async {
                                self.currentUser = nil
                                self.isLoggedIn = false
        }
    }
}
                } else {
                    // User is signed out - update on main thread
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

            for await userProfile in self.authService.fetchUserProfile(uid: currentUser.id).values {
                DispatchQueue.main.async {
                    self.currentUser = userProfile
                }
                break // We only need the first value
            }
        }
    }
}

