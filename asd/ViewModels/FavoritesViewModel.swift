import Foundation
import Combine

final class FavoritesViewModel: ObservableObject {
    @Published var favoriteProducts: [Product] = []
    @Published var currentUserId: String?

    private let favoritesService = FavoritesService()

    init() {}

    func setCurrentUserId(_ userId: String?) {
        currentUserId = userId
        fetchFavorites()
    }

    func addFavorite(_ product: Product) {
        guard let userId = currentUserId else { return }
        favoritesService.addFavorite(productId: product.id, userId: userId)
        fetchFavorites()
    }

    func removeFavorite(_ product: Product) {
        guard let userId = currentUserId else { return }
        favoritesService.removeFavorite(productId: product.id, userId: userId)
        fetchFavorites()
    }

    func fetchFavorites() {
        guard let userId = currentUserId else {
            favoriteProducts = []
            return
        }
        favoriteProducts = favoritesService.fetchFavoriteProducts(userId: userId)
    }
}

