import Foundation
import _LocationEssentials
import FirebaseFirestore
import FirebaseAuth

final class ProductService {
    private let db = Firestore.firestore()

    // MARK: - Fetch Products

    func fetchProducts() async throws -> [Product] {
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
        longitude: Double,
        imageUrls: [String],
        completion: @escaping (Result<Product, Error>) -> Void
    ) async {
        guard let currentUser = Auth.auth().currentUser else {
            completion(.failure(ProductError.notAuthenticated))
            return
        }

        do {
            // Validate price input
            guard let price = Double(priceText) else {
                throw ProductError.invalidPrice
            }

            let productId = UUID().uuidString

            let newProduct = Product(
                id: productId,
                title: title,
                description: description,
                price: price,
                category: category,
                imageUrls: imageUrls,
                sellerId: currentUser.uid,
                sellerName: currentUser.displayName ?? "Seller",
                locationName: locationName,
                latitude: latitude,
                longitude: longitude,
                rating: 0.0,
                createdAt: Date()
            )

            // Add to Firestore
            // Change from completion handler to async/await pattern
            try await db.collection("products").document(productId).setData(from: newProduct)

            completion(.success(newProduct))
            
        } catch {
            completion(.failure(error))
        }
    }

    // MARK: - Update Products

    func updateProduct(
        productId: String,
        title: String? = nil,
        description: String? = nil,
        category: String? = nil,
        priceText: String? = nil,
        locationName: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        imageUrls: [String]? = nil
    ) async throws -> Product {
        guard let currentUser = Auth.auth().currentUser else {
            throw ProductError.notAuthenticated
        }

        // Validate price if provided
        let price: Double?
        if let priceText = priceText, let validatedPrice = Double(priceText) {
            price = validatedPrice
        } else {
            price = nil
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Product, Error>) in
            db.collection("products").document(productId).getDocument { snapshot, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let existingProduct = try? snapshot?.data(as: Product.self) else {
                    continuation.resume(throwing: ProductError.productNotFound)
                    return
                }

                // Verify seller authorization
                if existingProduct.sellerId != currentUser.uid {
                    continuation.resume(throwing: ProductError.notAuthorized)
                    return
                }

                var updatedProduct = existingProduct

                if let title = title { updatedProduct.title = title }
                if let description = description { updatedProduct.description = description }
                if let category = category { updatedProduct.category = category }
                if let price = price { updatedProduct.price = price }
                if let locationName = locationName { updatedProduct.locationName = locationName }
                if let latitude = latitude { updatedProduct.latitude = latitude }
                if let longitude = longitude { updatedProduct.longitude = longitude }
                if let imageUrls = imageUrls { updatedProduct.imageUrls = imageUrls }

                // Update timestamp
                updatedProduct.createdAt = existingProduct.createdAt

                db.collection("products").document(productId).setData(from: updatedProduct) { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: updatedProduct)
                }
            }
        }
    }

    // MARK: - Delete Products

    func deleteProduct(productId: String) async throws -> Bool {
        guard let currentUser = Auth.auth().currentUser else {
            throw ProductError.notAuthenticated
        }
    
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            db.collection("products").document(productId).getDocument { snapshot, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
    
                guard let product = try? snapshot?.data(as: Product.self) else {
                    continuation.resume(returning: false)
                    return
                }

                // Verify seller authorization
                if product.sellerId != currentUser.uid {
                    continuation.resume(throwing: ProductError.notAuthorized)
                    return
                }

                self.db.collection("products").document(productId).delete { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: true)
                }
            }
        }
    }

    // MARK: - Search Products

    func searchProducts(query: String) async throws -> [Product] {
        try await withCheckedThrowingContinuation { continuation in
            db.collection("products")
                .whereField("title", isGreaterThanOrEqualTo: query)
                .whereField("title", isLessThan: query + "\u{fff}")
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
}

// MARK: - Error Handling

enum ProductError: Error, LocalizedError {
    case notAuthenticated
    case productNotFound
    case notAuthorized
    case invalidPrice
    case databaseError(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .productNotFound:
            return "Product not found"
        case .notAuthorized:
            return "You are not authorized to perform this action"
        case .invalidPrice:
            return "Invalid price format. Please enter a valid number."
        case .databaseError(let message):
            return "Database error: \(message)"
        }
    }
}
