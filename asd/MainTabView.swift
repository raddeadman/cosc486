import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack { ProductListView() }
                .tabItem { Label("Home", systemImage: "house") }

            NavigationStack { FavoritesView() }
                .tabItem { Label("Favorites", systemImage: "heart") }

            NavigationStack { AddProductView() }
                .tabItem { Label("Sell", systemImage: "plus.circle") }

            NavigationStack { ChatListView() }
                .tabItem { Label("Chats", systemImage: "message") }

            NavigationStack { ProfileView() }
                .tabItem { Label("Profile", systemImage: "person") }
        }
    }
}
