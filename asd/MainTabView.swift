import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                ProductListView()
                    .modifier(BurgerMenuToolbar())
            }
                .tabItem { Label("Home", systemImage: "house") }

            NavigationStack {
                ProductsMapTabView()
                    .modifier(BurgerMenuToolbar())
            }
                .tabItem { Label("Map", systemImage: "map") }

            NavigationStack {
                FavoritesView()
                    .modifier(BurgerMenuToolbar())
            }
                .tabItem { Label("Favorites", systemImage: "heart") }

            NavigationStack {
                AddProductView()
                    .modifier(BurgerMenuToolbar())
            }
                .tabItem { Label("Sell", systemImage: "plus.circle") }

            NavigationStack {
                ChatListView()
                    .modifier(BurgerMenuToolbar())
            }
                .tabItem { Label("Chats", systemImage: "message") }
        }
    }
}

private struct BurgerMenuToolbar: ViewModifier {
    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Menu {
                    NavigationLink {
                        MyListingsView()
                    } label: {
                        Label("My Listings", systemImage: "shippingbox")
                    }

                    NavigationLink {
                        ProfileView()
                    } label: {
                        Label("Profile", systemImage: "person")
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                }
            }
        }
    }
}
