import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel = FavoritesViewModel()

    var body: some View {
        Group {
            if viewModel.favoriteProducts.isEmpty {
                ContentUnavailableView("No Favorites", systemImage: "heart.slash")
            } else {
                List(viewModel.favoriteProducts) { product in
                    NavigationLink {
                        ProductDetailView(product: product)
                    } label: {
                        ProductCardView(product: product)
                    }
                }
            }
        }
        .navigationTitle("Favorites")
        .onAppear {
            viewModel.setCurrentUserId(authViewModel.currentUser?.id)
        }
        .onChange(of: authViewModel.currentUser?.id) { _, newUserId in
            viewModel.setCurrentUserId(newUserId)
        }
    }
}
