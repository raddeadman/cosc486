import Foundation
import Combine

// MARK: - Review Service
// Handles all review-related operations with the backend API

enum ReviewError: Error, LocalizedError {
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

final class ReviewService {
    private let baseURL = "https://us-central1-openmarketmobile.cloudfunctions.net"

    private struct APIErrorResponse: Decodable {
        let error: String
    }

    private func validatedData(
        from output: URLSession.DataTaskPublisher.Output,
        successCodes: Set<Int>
    ) throws -> Data {
        guard let httpResponse = output.response as? HTTPURLResponse else {
            throw ReviewError.serverError("Invalid server response")
        }
        if successCodes.contains(httpResponse.statusCode) {
            return output.data
        }
        let msg: String
        if let api = try? JSONDecoder().decode(APIErrorResponse.self, from: output.data) {
            msg = api.error
        } else if let text = String(data: output.data, encoding: .utf8), !text.isEmpty {
            msg = text
        } else {
            msg = "Unexpected server error"
        }
        throw ReviewError.serverError("Request failed (\(httpResponse.statusCode)): \(msg)")
    }

    // MARK: - Fetch Reviews (seller)

    func fetchReviews(sellerId: String) -> AnyPublisher<[Review], Error> {
        guard !sellerId.isEmpty else {
            return Fail(error: ReviewError.invalidParameters).eraseToAnyPublisher()
        }

        var components = URLComponents(string: "\(baseURL)/fetchReviews")!
        components.queryItems = [URLQueryItem(name: "sellerId", value: sellerId)]
        guard let url = components.url else {
            return Fail(error: ReviewError.invalidParameters).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = TokenManager.get() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { [weak self] output in
                guard let self else { throw ReviewError.serverError("Service unavailable") }
                let data = try self.validatedData(from: output, successCodes: [200])
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode([Review].self, from: data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Fetch product reviews

    func fetchProductReviews(productId: String) -> AnyPublisher<[Review], Error> {
        guard !productId.isEmpty else {
            return Fail(error: ReviewError.invalidParameters).eraseToAnyPublisher()
        }

        var components = URLComponents(string: "\(baseURL)/fetchProductReviews")!
        components.queryItems = [URLQueryItem(name: "productId", value: productId)]
        guard let url = components.url else {
            return Fail(error: ReviewError.invalidParameters).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = TokenManager.get() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { [weak self] output in
                guard let self else { throw ReviewError.serverError("Service unavailable") }
                let data = try self.validatedData(from: output, successCodes: [200])
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode([Review].self, from: data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Add Review

    func addReview(
        productId: String,
        sellerId: String,
        rating: Int,
        comment: String?
    ) -> AnyPublisher<Review, Error> {
        guard !productId.isEmpty, !sellerId.isEmpty else {
            return Fail(error: ReviewError.invalidParameters).eraseToAnyPublisher()
        }

        let urlString = "\(baseURL)/addReview"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = TokenManager.get() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let requestBody: [String: Any] = [
            "productId": productId,
            "sellerId": sellerId,
            "rating": rating,
            "comment": comment ?? ""
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            return Fail(error: ReviewError.invalidParameters).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { [weak self] output in
                guard let self else { throw ReviewError.serverError("Service unavailable") }
                let data = try self.validatedData(from: output, successCodes: [201])
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(Review.self, from: data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
