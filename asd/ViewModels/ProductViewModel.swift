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
            return categorized.sorted(by: { $0.rating > $1.rating })
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
        productService.fetchProducts()
            .sink { [weak self] completion in
                guard let self else { return }
                self.isLoading = false
                self.isRefreshing = false
                if case .failure = completion {
                    if self.products.isEmpty { self.products = [] }
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
        productService.updateProductAvailability(productId: product.id, userId: userId, isAvailable: isAvailable)
            .sink { completion in
                // Handle completion if needed
            } receiveValue: { updatedProduct in
                self.products = self.products.map { current in
                    guard current.id == product.id else { return current }
                    return Product(
                        id: current.id,
                        title: current.title,
                        description: current.description,
                        price: current.price,
                        category: current.category,
                        imageUrls: current.imageUrls,
                        sellerId: current.sellerId,
                        sellerName: current.sellerName,
                        locationName: current.locationName,
                        latitude: current.latitude,
                        longitude: current.longitude,
                        rating: current.rating,
                        reviewAverage: current.reviewAverage,
                        reviewCount: current.reviewCount,
                        isAvailable: isAvailable,
                        createdAt: current.createdAt
                    )
                }
            }
            .store(in: &cancellables)
    }
    
}
