import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    var body: some View {
        TabView {
            // Home Tab
            NavigationStack {
                ProductListView()
                    .environmentObject(authViewModel)
            }
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            // Favorites Tab
            NavigationStack {
                if !authViewModel.currentUser?.favorites.isEmpty ?? false {
                    List(authViewModel.currentUser?.favorites) { product in
                        NavigationLink {
                            ProductDetailView(product: product)
                        } label: {
                            ProductCardView(product: product)
                        }
                    }
                } else {
                    ContentUnavailableView("No Favorites", systemImage: "heart.slash") {
                        Text("You haven't added any products to favorites yet.")
                    }
                }
            }
                .tabItem {
                    Label("Favorites", systemImage: "heart")
                }

            // Sell Tab
            NavigationStack {
                AddProductView()
                    .environmentObject(authViewModel)
            }
                .tabItem {
                    Label("Sell", systemImage: "plus.circle")
                }

            // Chats Tab
            NavigationStack {
                if !authViewModel.currentUser?.chats.isEmpty ?? false {
                    ChatListView()
                        .environmentObject(authViewModel)
                } else {
                    ContentUnavailableView("No Chats", systemImage: "message.badge.plus") {
                        Text("You haven't started any conversations yet.")
                    }
                }
            }
                .tabItem {
                    Label("Chats", systemImage: "message")
                }

            // Profile Tab
            NavigationStack {
                if let user = authViewModel.currentUser {
                    ProfileView(user: user)
                } else {
                    Text("Loading...")
                }
            }
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
    }
}

struct ProfileView: View {
    let user: User
    @EnvironmentObject private var authViewModel: AuthViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Header
                HStack(alignment: .center, spacing: 16) {
                    // Avatar Placeholder
                    Circle()
                        .fill(.gray.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .overlay(Image(systemName: "person.circle"))
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.name)
                            .font(.title2.bold())

                        Text(user.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("Member since \(user.shortDateText)")
                            .font(.caption)
                            .foregroundColor(.tertiary)
                    }
                }

                Divider()

                // Stats Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Account Statistics")
                        .font(.headline)

                    HStack {
                        Spacer()
                        Text("Average Rating:")
                            .foregroundColor(.secondary)

                        Text("\(user.ratingAverage.formatted(.number.precision(.fractionLength(1))))⭐")
                            .fontWeight(.bold)
                            .foregroundColor(user.ratingAverage > 4 ? .green : .orange)
                    }
                }

                Divider()

                // Quick Actions
                VStack(spacing: 12) {
                    Button {
                        authViewModel.logout()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.left.circle")
                                .foregroundColor(.red)

                            Text("Logout")
                                .fontWeight(.semibold)

                            Spacer()

                            Image(systemName: "arrow.right.circle")
                                .foregroundColor(.red)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
        }
    }
}

