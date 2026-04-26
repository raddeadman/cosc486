import Foundation

final class FavoritesService {
    private var favoriteProductIDs: Set<String> = []

    func addFavorite(productId: String) {
        favoriteProductIDs.insert(productId)
    }

    func removeFavorite(productId: String) {
        favoriteProductIDs.remove(productId)
    }

    func fetchFavoriteProducts() -> [Product] {
        MockData.products.filter { favoriteProductIDs.contains($0.id) }
    }
}
