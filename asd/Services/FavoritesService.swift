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
    private let baseURL = "https://api.example.com/v1"

    // MARK: - Fetch Favorite Products

    func fetchFavoriteProducts(userId: String, token: String) -> AnyPublisher<[Product], Error> {
        guard !userId.isEmpty else {
            return Fail(error: FavoritesError.invalidParameters).eraseToAnyPublisher()
        }

        let urlString = "\(baseURL)/users/\(userId)/favorites"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap(\.response)
            .decode(type: [Product].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Add Favorite

    func addFavorite(productId: String, userId: String, token: String) -> AnyPublisher<Bool, Error> {
        guard !productId.isEmpty, !userId.isEmpty else {
            return Fail(error: FavoritesError.invalidParameters).eraseToAnyPublisher()
        }

        let urlString = "\(baseURL)/users/\(userId)/favorites"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

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

    func removeFavorite(productId: String, userId: String, token: String) -> AnyPublisher<Bool, Error> {
        guard !productId.isEmpty, !userId.isEmpty else {
            return Fail(error: FavoritesError.invalidParameters).eraseToAnyPublisher()
        }

        let urlString = "\(baseURL)/users/\(userId)/favorites/\(productId)"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { _ in true }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}