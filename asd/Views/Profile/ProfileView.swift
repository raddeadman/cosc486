import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    var body: some View {
        List {
            Section("Account") {
                Text(authViewModel.currentUser?.name ?? "Guest")
                Text(authViewModel.currentUser?.email ?? "-")
                Text("Average rating: \((authViewModel.currentUser?.ratingAverage ?? 0).formatted(.number.precision(.fractionLength(1))))")
            }

            Section("Actions") {
                NavigationLink("My Listings") { MyListingsView() }
                NavigationLink("Favorites") { FavoritesView() }
                Button("Logout", role: .destructive) { authViewModel.logout() }
            }
        }
        .navigationTitle("Profile")
    }
}
