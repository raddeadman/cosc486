import Foundation
import Combine

final class ProductViewModel: ObservableObject {
    @Published var products: [Product] = MockData.products
    @Published var searchText = ""
    @Published var selectedCategory = "All"
    @Published var selectedSort = "Date"

    private let productService = ProductService()

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

    func fetchProducts() {
        products = productService.fetchProducts()
    }

    func productsForSeller(userId: String) -> [Product] {
        products.filter { $0.sellerId == userId }
    }

    func updateAvailability(product: Product, isAvailable: Bool, userId: String) {
        productService.updateProductAvailability(productId: product.id, userId: userId, isAvailable: isAvailable)
        products = products.map { current in
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
                isAvailable: isAvailable,
                createdAt: current.createdAt
            )
        }
    }
}

