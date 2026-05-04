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

    private struct APIErrorResponse: Decodable {
        let error: String
    }

    private func validatedData(
        from output: URLSession.DataTaskPublisher.Output,
        successCodes: Set<Int>
    ) throws -> Data {
        guard let httpResponse = output.response as? HTTPURLResponse else {
            throw ProductError.serverError("Invalid server response")
        }
        if successCodes.contains(httpResponse.statusCode) {
            return output.data
        }
        let message: String
        if let api = try? JSONDecoder().decode(APIErrorResponse.self, from: output.data) {
            message = api.error
        } else if let text = String(data: output.data, encoding: .utf8), !text.isEmpty {
            message = text
        } else {
            message = "Unexpected server error"
        }
        throw ProductError.serverError("Request failed (\(httpResponse.statusCode)): \(message)")
    }

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
            .tryMap { [weak self] output in
                guard let self else { throw ProductError.serverError("Service unavailable") }
                let data = try self.validatedData(from: output, successCodes: [200])
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode([Product].self, from: data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Fetch Single Product

    func fetchProduct(productId: String) -> AnyPublisher<Product?, Error> {
        guard !productId.isEmpty else {
            return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()
        }

        return fetchProducts()
            .map { products in
                products.first(where: { $0.id == productId })
            }
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
        longitude: Double,
        imageUrls: [String] = []
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
            "priceText": priceText,
            "locationName": locationName,
            "latitude": latitude,
            "longitude": longitude,
            "imageUrls": imageUrls
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            return Fail(error: ProductError.invalidParameters).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { [weak self] output in
                guard let self else { throw ProductError.serverError("Service unavailable") }
                let data = try self.validatedData(from: output, successCodes: [201])
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(Product.self, from: data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Update Product Availability

    func fetchMyProducts() -> AnyPublisher<[Product], Error> {
        let urlString = "\(baseURL)/fetchMyProducts"
        guard let url = URL(string: urlString) else {
            return Fail(error: ProductError.invalidParameters).eraseToAnyPublisher()
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = TokenManager.get() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { [weak self] output in
                guard let self else { throw ProductError.serverError("Service unavailable") }
                let data = try self.validatedData(from: output, successCodes: [200])
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode([Product].self, from: data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func updateProductAvailability(
        productId: String,
        userId: String,
        isAvailable: Bool
    ) -> AnyPublisher<Product, Error> {
        var components = URLComponents(string: "\(baseURL)/updateProductAvailability")!
        components.queryItems = [URLQueryItem(name: "productId", value: productId)]
        guard let url = components.url else {
            return Fail(error: ProductError.invalidParameters).eraseToAnyPublisher()
        }
        var request = URLRequest(url: url)
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
            .tryMap { [weak self] output in
                guard let self else { throw ProductError.serverError("Service unavailable") }
                let data = try self.validatedData(from: output, successCodes: [200])
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(Product.self, from: data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
