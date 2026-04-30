import Foundation

final class ProductService {
    func fetchProducts() -> [Product] {
        // API placeholder:
        // let url = URL(string: "https://api.example.com/v1/products?search=\(query)&category=\(category)&sort=\(sort)")!
        // let (data, _) = try await URLSession.shared.data(from: url)
        // let products = try JSONDecoder().decode([Product].self, from: data)
        // return products
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
        // API placeholder:
        // let url = URL(string: "https://api.example.com/v1/products")!
        // var request = URLRequest(url: url)
        // request.httpMethod = "POST"
        // request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // request.httpBody = try JSONEncoder().encode([
        //   "title": title,
        //   "description": description,
        //   "category": category,
        //   "price": priceText,
        //   "isAvailable": true,
        //   "locationName": locationName,
        //   "latitude": latitude,
        //   "longitude": longitude
        // ])
        // let (_, _) = try await URLSession.shared.data(for: request)
        _ = (title, description, category, priceText, locationName, latitude, longitude)
    }

    func updateProductAvailability(productId: String, userId: String, isAvailable: Bool) {
        // API placeholder:
        // PATCH https://api.example.com/v1/users/{userId}/products/{productId}/availability
        // Body: { "isAvailable": isAvailable }
        // let (_, _) = try await URLSession.shared.data(for: request)
        _ = (productId, userId, isAvailable)
    }
}
