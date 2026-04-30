import Foundation
import _LocationEssentials
import FirebaseFirestore
import FirebaseAuth

final class ProductService {
    private let db = Firestore.firestore()

    // MARK: - Fetch Products

    func fetchProducts() async throws -> [Product] {
        // API placeholder:
        // let url = URL(string: "https://api.example.com/v1/products?search=\(query)&category=\(category)&sort=\(sort)")!
        // let (data, _) = try await URLSession.shared.data(from: url)
        // let products = try JSONDecoder().decode([Product].self, from: data)
        // return products
        try await withCheckedThrowingContinuation { continuation in
            db.collection("products")
                .getDocuments { querySnapshot, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }

                    guard let documents = querySnapshot?.documents else {
                        continuation.resume(returning: [])
                        return
                    }

                    let products = documents.compactMap { doc -> Product? in
                        try? doc.data(as: Product.self)
                    }.sorted { $0.createdAt > $1.createdAt } // Newest first

                    continuation.resume(returning: products)
                }
        }
    }

    func fetchProducts(by category: String) async throws -> [Product] {
        try await withCheckedThrowingContinuation { continuation in
            db.collection("products")
                .whereField("category", isEqualTo: category)
                .getDocuments { querySnapshot, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }

                    guard let documents = querySnapshot?.documents else {
                        continuation.resume(returning: [])
                        return
                    }

                    let products = documents.compactMap { doc -> Product? in
                        try? doc.data(as: Product.self)
                    }.sorted { $0.createdAt > $1.createdAt }

                    continuation.resume(returning: products)
                }
        }
    }

    func fetchProducts(near location: CLLocation, maxDistance: Double) async throws -> [Product] {
        try await withCheckedThrowingContinuation { continuation in
            db.collection("products")
                .whereField("latitude", isGreaterThanOrEqualTo: location.coordinate.latitude - maxDistance)
                .whereField("latitude", isLessThanOrEqualTo: location.coordinate.latitude + maxDistance)
                .whereField("longitude", isGreaterThanOrEqualTo: location.coordinate.longitude - maxDistance)
                .whereField("longitude", isLessThanOrEqualTo: location.coordinate.longitude + maxDistance)
                .getDocuments { querySnapshot, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }

                    guard let documents = querySnapshot?.documents else {
                        continuation.resume(returning: [])
                        return
                    }

                    // Calculate distance and filter products within maxDistance
                    let nearbyProducts = documents.compactMap { doc -> Product? in
                        try? doc.data(as: Product.self)
                    }.filter { product in
                        let userLocation = CLLocation(latitude: location.coordinate.latitude,
                                                     longitude: location.coordinate.longitude)
                        let productLocation = CLLocation(latitude: product.latitude,
                                                       longitude: product.longitude)
                        return userLocation.distance(from: productLocation) <= maxDistance * 1000 // Convert to meters
                    }.sorted { $0.createdAt > $1.createdAt }

                    continuation.resume(returning: nearbyProducts)
                }
        }
    }

    func fetchProduct(id: String) async throws -> Product? {
        try await withCheckedThrowingContinuation { continuation in
            db.collection("products").document(id).getDocument { snapshot, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let product = try? snapshot?.data(as: Product.self) else {
                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(returning: product)
            }
        }
    }

    // MARK: - Create Products

    func createProduct(
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

    func updateProductAvailability(productId: String, userId: String, isAvailable: Bool) {
        // API placeholder:
        // PATCH https://api.example.com/v1/users/{userId}/products/{productId}/availability
        // Body: { "isAvailable": isAvailable }
        // let (_, _) = try await URLSession.shared.data(for: request)
        _ = (productId, userId, isAvailable)
    }
}
