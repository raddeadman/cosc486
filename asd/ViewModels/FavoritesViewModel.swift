import Foundation
import Combine

final class FavoritesViewModel: ObservableObject {
    @Published var favoriteProducts: [Product] = []

    private let favoritesService = FavoritesService()

    init() {
        fetchFavorites()
    }

    func addFavorite(_ product: Product) {
        favoritesService.addFavorite(productId: product.id)
        fetchFavorites()
    }

    func removeFavorite(_ product: Product) {
        favoritesService.removeFavorite(productId: product.id)
        fetchFavorites()
    }

    func fetchFavorites() {
        favoriteProducts = favoritesService.fetchFavoriteProducts()
    }
}
