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
    
    private struct APIErrorResponse: Decodable {
        let error: String
    }

    private func validatedData(
        from output: URLSession.DataTaskPublisher.Output,
        successCodes: Set<Int>
    ) throws -> Data {
        guard let httpResponse = output.response as? HTTPURLResponse else {
            throw FavoritesError.serverError("Invalid server response")
        }

        if successCodes.contains(httpResponse.statusCode) {
            return output.data
        }

        let errorMessage = extractErrorMessage(from: output.data)
        throw FavoritesError.serverError("Request failed (\(httpResponse.statusCode)): \(errorMessage)")
    }

    private func extractErrorMessage(from data: Data) -> String {
        if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
            return apiError.error
        }

        if let text = String(data: data, encoding: .utf8), !text.isEmpty {
            return text
        }

        return "Unexpected server error"
    }

    // MARK: - Fetch Favorite Products

    func fetchFavoriteProducts() -> AnyPublisher<[Product], Error> {
        let urlString = "\(baseURL)/fetchFavoriteProducts"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "GET"

        if let token = TokenManager.get() {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { [weak self] response in
                guard let self else { throw FavoritesError.serverError("Service unavailable") }
                let data = try self.validatedData(from: response, successCodes: [200])
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode([Product].self, from: data)
    }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Add Favorite

    func addFavorite(productId: String) -> AnyPublisher<Bool, Error> {
        guard !productId.isEmpty else {
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
            .tryMap { [weak self] response in
                guard let self else { throw FavoritesError.serverError("Service unavailable") }
                _ = try self.validatedData(from: response, successCodes: [201])
                return true
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Remove Favorite

    func removeFavorite(productId: String) -> AnyPublisher<Bool, Error> {
        guard !productId.isEmpty else {
            return Fail(error: FavoritesError.invalidParameters).eraseToAnyPublisher()
        }

        let urlString = "\(baseURL)/removeFavorite"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "DELETE"
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
            .tryMap { [weak self] response in
                guard let self else { throw FavoritesError.serverError("Service unavailable") }
                _ = try self.validatedData(from: response, successCodes: [200])
                return true
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
