import Foundation
import Combine

// MARK: - Product Service
// Handles all product-related operations with the backend API

enum ProductError: Error, LocalizedError {
    case invalidParameters
    case networkError(Error)
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidParameters:
            return "Invalid parameters provided"
        case .networkError(let error):
            return error.localizedDescription
        case .serverError(let message):
            return message
        }
    }
}

final class ProductService {
    private let baseURL = "https://us-central1-openmarketmobile.cloudfunctions.net"

    // MARK: - Fetch Products

    func fetchProducts(
        search: String? = nil,
        category: String? = nil,
        sort: String? = nil,
        lat: Double? = nil,
        lng: Double? = nil,
        radiusKm: Int? = nil
    ) -> AnyPublisher<[Product], Error> {
        var urlString = "\(baseURL)/fetchProducts"
        if let search = search, !search.isEmpty {
            urlString += "?search=\(search)"
        }
        if let category = category, !category.isEmpty {
            if urlString.contains("?") {
                urlString += "&category=\(category)"
            } else {
                urlString += "?category=\(category)"
            }
        }
        if let sort = sort, !sort.isEmpty {
            if urlString.contains("?") {
                urlString += "&sort=\(sort)"
            } else {
                urlString += "?sort=\(sort)"
            }
        }
        if let lat = lat, let lng = lng, let radiusKm = radiusKm {
            if urlString.contains("?") {
                urlString += "&lat=\(lat)&lng=\(lng)&radiusKm=\(radiusKm)"
            } else {
                urlString += "?lat=\(lat)&lng=\(lng)&radiusKm=\(radiusKm)"
            }
        }

        guard let url = URL(string: urlString) else {
            return Fail(error: ProductError.invalidParameters).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { response in
                let decoder = JSONDecoder()
                return try decoder.decode([Product].self, from: response.data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Submit Placeholder Product

    func submitPlaceholderProduct(
        title: String,
        description: String,
        category: String,
        priceText: String,
        locationName: String,
        latitude: Double,
        longitude: Double
    ) -> AnyPublisher<Product, Error> {
        guard !title.isEmpty, !description.isEmpty, !category.isEmpty, !priceText.isEmpty, !locationName.isEmpty else {
            return Fail(error: ProductError.invalidParameters).eraseToAnyPublisher()
        }

        let urlString = "\(baseURL)/submitPlaceholderProduct"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = TokenManager.get() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Convert priceText to Double
        guard let price = Double(priceText) else {
            return Fail(error: ProductError.invalidParameters).eraseToAnyPublisher()
        }

        let requestBody: [String: Any] = [
            "title": title,
            "description": description,
            "category": category,
            "price": price,
            "isAvailable": true,
            "locationName": locationName,
            "latitude": latitude,
            "longitude": longitude
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            return Fail(error: ProductError.invalidParameters).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { response in
                let decoder = JSONDecoder()
                return try decoder.decode(Product.self, from: response.data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Update Product Availability

    func updateProductAvailability(
        productId: String,
        userId: String,
        isAvailable: Bool
    ) -> AnyPublisher<Product, Error> {
        let urlString = "\(baseURL)/updateProductAvailability"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = TokenManager.get() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let requestBody: [String: Any] = [
            "isAvailable": isAvailable
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            return Fail(error: ProductError.invalidParameters).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { response in
                let decoder = JSONDecoder()
                return try decoder.decode(Product.self, from: response.data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
