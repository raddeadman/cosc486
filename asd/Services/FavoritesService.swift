import Foundation
import Combine

// MARK: - Favorites Service
// Handles all favorites-related operations with the backend API

enum FavoritesError: Error, LocalizedError {
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

final class FavoritesService {
    private let baseURL = "https://us-central1-openmarketmobile.cloudfunctions.net"

    // MARK: - Fetch Favorite Products

    func fetchFavoriteProducts(userId: String) -> AnyPublisher<[Product], Error> {
        guard !userId.isEmpty else {
            return Fail(error: FavoritesError.invalidParameters).eraseToAnyPublisher()
        }

        let urlString = "\(baseURL)/fetchFavoriteProducts"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "GET"

        if let token = TokenManager.get() {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { response in
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode([Product].self, from: response.data)
    }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Add Favorite

    func addFavorite(productId: String, userId: String) -> AnyPublisher<Bool, Error> {
        guard !productId.isEmpty, !userId.isEmpty else {
            return Fail(error: FavoritesError.invalidParameters).eraseToAnyPublisher()
        }

        let urlString = "\(baseURL)/addFavorite"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = TokenManager.get() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

        let requestBody: [String: Any] = [
            "productId": productId
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            return Fail(error: FavoritesError.invalidParameters).eraseToAnyPublisher()
}

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { _ in true }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Remove Favorite

    func removeFavorite(productId: String, userId: String) -> AnyPublisher<Bool, Error> {
        guard !productId.isEmpty, !userId.isEmpty else {
            return Fail(error: FavoritesError.invalidParameters).eraseToAnyPublisher()
        }

        let urlString = "\(baseURL)/removeFavorite"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "DELETE"

        if let token = TokenManager.get() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { _ in true }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
