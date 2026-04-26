import SwiftUI

struct FavoritesView: View {
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
    }
}
