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
        locationName: String,
        latitude: Double,
        longitude: Double
    ) {
        _ = (title, description, category, priceText, locationName, latitude, longitude)
    }
}
