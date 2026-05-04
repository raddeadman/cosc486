import Foundation
import Combine
import SwiftUI

final class FavoritesViewModel: ObservableObject {
    @Published var favoriteProducts: [Product] = []
    @Published var currentUserId: String?
    @Published var isLoading = false
    @Published var hasLoadedOnce = false
    @Published var errorMessage: String?

    private let favoritesService = FavoritesService()
    private var cancellables = Set<AnyCancellable>()

    func setCurrentUserId(_ userId: String?) {
        currentUserId = userId
        fetchFavorites(isRefresh: false)
    }

    func isFavorite(productId: String) -> Bool {
        favoriteProducts.contains { $0.id == productId }
    }

    func addFavorite(_ product: Product) {
        guard currentUserId != nil else { return }
        guard !isFavorite(productId: product.id) else { return }

        let previous = favoriteProducts
        favoriteProducts.insert(product, at: 0)

        favoritesService.addFavorite(productId: product.id)
            .sink { [weak self] completion in
                guard let self else { return }
                if case .failure(let error) = completion {
                    self.favoriteProducts = previous
                    self.errorMessage = error.localizedDescription
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }

    func removeFavorite(_ product: Product) {
        guard currentUserId != nil else { return }

        let previous = favoriteProducts
        withAnimation(.easeInOut(duration: 0.2)) {
            favoriteProducts.removeAll { $0.id == product.id }
        }

        favoritesService.removeFavorite(productId: product.id)
            .sink { [weak self] completion in
                guard let self else { return }
                if case .failure(let error) = completion {
                    self.favoriteProducts = previous
                    self.errorMessage = error.localizedDescription
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }

    func fetchFavorites(isRefresh: Bool = false) {
        guard currentUserId != nil else {
            favoriteProducts = []
            hasLoadedOnce = false
            return
        }
        if isRefresh && hasLoadedOnce && !favoriteProducts.isEmpty {
            // subtle refresh
        } else {
            isLoading = true
        }
        errorMessage = nil
        favoritesService.fetchFavoriteProducts()
            .sink { [weak self] completion in
                guard let self else { return }
                self.isLoading = false
                if case .failure(let error) = completion {
                    self.errorMessage = error.localizedDescription
                    if !self.hasLoadedOnce {
                        self.favoriteProducts = []
                    }
                }
            } receiveValue: { [weak self] products in
                guard let self else { return }
                self.favoriteProducts = products
                self.hasLoadedOnce = true
            }
            .store(in: &cancellables)
    }
}
