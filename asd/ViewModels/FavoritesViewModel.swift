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
        guard currentUserId != nil else { return }
        favoritesService.addFavorite(productId: product.id)
            .sink { completion in
                // Handle completion if needed
            } receiveValue: { _ in
                self.fetchFavorites()
            }
            .store(in: &cancellables)
    }

    func removeFavorite(_ product: Product) {
        guard currentUserId != nil else { return }
        favoritesService.removeFavorite(productId: product.id)
            .sink { completion in
                // Handle completion if needed
            } receiveValue: { _ in
                self.fetchFavorites()
            }
            .store(in: &cancellables)
    }

    func fetchFavorites() {
        guard currentUserId != nil else {
            favoriteProducts = []
            return
        }
        favoritesService.fetchFavoriteProducts()
            .sink { completion in
                // Handle completion if needed
            } receiveValue: { products in
                self.favoriteProducts = products
            }
            .store(in: &cancellables)
    }
}

