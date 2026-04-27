import SwiftUI

import FirebaseCore

import FirebaseAuth


@main
struct MarketplaceApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    init() {
        // Configure Firebase initialization
        FirebaseApp.configure()

        let authViewModel = self.authViewModel
        Task.detached(priority: .background) {
            await authViewModel.fetchCurrentUser()
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isLoggedIn && authViewModel.userDisplayName != nil {
                    MainTabView()
                } else {
                    NavigationStack {
                        LoginView()
                    }
                }
            }
            .environmentObject(authViewModel)
        }
    }
}
