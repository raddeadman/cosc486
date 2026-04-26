import SwiftUI
#if canImport(FirebaseCore)
import FirebaseCore
#endif

@main
struct MarketplaceApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    init() {
        #if canImport(FirebaseCore)
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            if authViewModel.isLoggedIn {
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
