import Foundation
import Combine

final class FavoritesViewModel: ObservableObject {
    @Published var favoriteProducts: [Product] = []
    @Published var currentUserId: String?

    private let favoritesService = FavoritesService()
    private var cancellables = Set<AnyCancellable>()

    init() {}

    func setCurrentUserId(_ userId: String?) {
        currentUserId = userId
        fetchFavorites()
    }

    func addFavorite(_ product: Product) {
        guard let userId = currentUserId else { return }
        favoritesService.addFavorite(productId: product.id, userId: userId)
            .sink { completion in
                // Handle completion if needed
            } receiveValue: { _ in
                self.fetchFavorites()
            }
            .store(in: &cancellables)
    }

    func removeFavorite(_ product: Product) {
        guard let userId = currentUserId else { return }
        favoritesService.removeFavorite(productId: product.id, userId: userId)
            .sink { completion in
                // Handle completion if needed
            } receiveValue: { _ in
                self.fetchFavorites()
            }
            .store(in: &cancellables)
    }

    func fetchFavorites() {
        guard let userId = currentUserId else {
            favoriteProducts = []
            return
        }
        favoritesService.fetchFavoriteProducts(userId: userId)
            .sink { completion in
                // Handle completion if needed
            } receiveValue: { products in
                self.favoriteProducts = products
            }
            .store(in: &cancellables)
    }
}

