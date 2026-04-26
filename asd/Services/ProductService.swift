import Foundation

final class ProductService {
    func fetchProducts() -> [Product] {
        MockData.products
    }

    func submitPlaceholderProduct(
        title: String,
        description: String,
        category: String,
        priceText: String,
        locationName: String
    ) {
        _ = (title, description, category, priceText, locationName)
    }
}
