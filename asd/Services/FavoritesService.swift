import Foundation

final class FavoritesService {
    private var favoriteProductIDsByUser: [String: Set<String>] = [:]

    func addFavorite(productId: String, userId: String) {
        // API placeholder:
        // POST https://api.example.com/v1/users/{userId}/favorites
        // Body: { "productId": productId }
        // let (_, _) = try await URLSession.shared.data(for: request)
        var favorites = favoriteProductIDsByUser[userId, default: []]
        favorites.insert(productId)
        favoriteProductIDsByUser[userId] = favorites
    }

    func removeFavorite(productId: String, userId: String) {
        // API placeholder:
        // DELETE https://api.example.com/v1/users/{userId}/favorites/{productId}
        // let (_, _) = try await URLSession.shared.data(for: request)
        var favorites = favoriteProductIDsByUser[userId, default: []]
        favorites.remove(productId)
        favoriteProductIDsByUser[userId] = favorites
    }

    func fetchFavoriteProducts(userId: String) -> [Product] {
        // API placeholder:
        // GET https://api.example.com/v1/users/{userId}/favorites
        // let (data, _) = try await URLSession.shared.data(from: url)
        // return try JSONDecoder().decode([Product].self, from: data)
        let favorites = favoriteProductIDsByUser[userId, default: []]
        return MockData.products.filter { favorites.contains($0.id) }
    }
}
