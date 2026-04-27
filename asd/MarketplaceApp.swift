import SwiftUI
#if canImport(FirebaseCore)
import FirebaseCore
#endif

@main
struct MarketplaceApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    init() {
        #if canImport(FirebaseCore)



        // Configure Firebase initialization
        FirebaseApp.configure()
        #endif


        Task.detached { [weak self] in
            await self?.authViewModel.fetchCurrentUser()
        }
    }

    var body: some Scene {
        WindowGroup {

            if authViewModel.isLoggedIn && authViewModel.userDisplayName != nil {
                MainTabView()
                    .environmentObject(authViewModel)
            } else {
                NavigationStack {
                    LoginView()
                        .environmentObject(authViewModel)
                }
            }
        }
    }
}

extension AuthViewModel {
    func fetchCurrentUser() async {
        let auth = Auth.auth()

        do {
            let user = try await auth.signInAnonymously()
            currentUser = User(
                id: user.uid,
                name: "Guest",
                email: "",
                profileImageUrl: "",
                ratingAverage: 0.0,
                createdAt: .now
            )
            isLoggedIn = true
        } catch {
            print("Failed to fetch current user: \(error)")
        }
    }
}