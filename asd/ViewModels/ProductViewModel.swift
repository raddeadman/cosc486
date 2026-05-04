import Foundation
import Combine

final class ProductViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var searchText = ""
    @Published var selectedCategory = "All"
    @Published var selectedSort = "Date"
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var hasLoadedOnce = false
    @Published var listingErrorMessage: String?

    private let productService = ProductService()
    private var cancellables = Set<AnyCancellable>()

    var filteredProducts: [Product] {
        let searched = products.filter {
            searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText)
        }
        let categorized = searched.filter {
            selectedCategory == "All" || $0.category == selectedCategory
        }
        switch selectedSort {
        case "Price":
            return categorized.sorted(by: { $0.price < $1.price })
        case "Rating":
            return categorized.sorted { a, b in
                if a.reviewAverage != b.reviewAverage {
                    return a.reviewAverage > b.reviewAverage
                }
                if a.reviewCount != b.reviewCount {
                    return a.reviewCount > b.reviewCount
                }
                return a.createdAt > b.createdAt
            }
        default:
            return categorized.sorted(by: { $0.createdAt > $1.createdAt })
        }
    }

    func fetchProducts(isRefresh: Bool = false) {
        if isRefresh && hasLoadedOnce && !products.isEmpty {
            isRefreshing = true
        } else {
            isLoading = true
        }
        listingErrorMessage = nil
        productService.fetchProducts()
            .sink { [weak self] completion in
                guard let self else { return }
                self.isLoading = false
                self.isRefreshing = false
                if case .failure(let err) = completion {
                    if self.products.isEmpty { self.products = [] }
                    self.listingErrorMessage = err.localizedDescription
                }
            } receiveValue: { [weak self] products in
                guard let self else { return }
                self.products = products.filter { $0.isAvailable }
                self.hasLoadedOnce = true
            }
            .store(in: &cancellables)
    }

    /// Seller's own listings, including unavailable.
    func fetchMyListings() {
        isLoading = true
        listingErrorMessage = nil
        productService.fetchMyProducts()
            .sink { [weak self] completion in
                guard let self else { return }
                self.isLoading = false
                if case .failure(let err) = completion {
                    self.products = []
                    self.listingErrorMessage = err.localizedDescription
                }
            } receiveValue: { [weak self] products in
                guard let self else { return }
                self.products = products
                self.hasLoadedOnce = true
            }
            .store(in: &cancellables)
    }

    func productsForSeller(userId: String) -> [Product] {
        products.filter { $0.sellerId == userId }
    }

    func updateAvailability(product: Product, isAvailable: Bool, userId: String) {
        listingErrorMessage = nil
        productService.updateProductAvailability(productId: product.id, userId: userId, isAvailable: isAvailable)
            .sink { [weak self] completion in
                if case .failure(let err) = completion {
                    self?.listingErrorMessage = err.localizedDescription
                }
            } receiveValue: { [weak self] updated in
                guard let self else { return }
                self.products = self.products.map { current in
                    guard current.id == updated.id else { return current }
                    return updated
                }
            }
            .store(in: &cancellables)
    }
}
