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

    // MARK: - Fetch Reviews

    func fetchReviews(sellerId: String) -> AnyPublisher<[Review], Error> {
        guard !sellerId.isEmpty else {
            return Fail(error: ReviewError.invalidParameters).eraseToAnyPublisher()
        }

        let urlString = "\(baseURL)/fetchReviews?sellerId=\(sellerId)"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "GET"

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { response in
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode([Review].self, from: response.data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Add Review

    func addReview(
        sellerId: String,
        reviewerId: String,
        rating: Int,
        comment: String? = nil
    ) -> AnyPublisher<Review, Error> {
        guard !sellerId.isEmpty, !reviewerId.isEmpty else {
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
            "sellerId": sellerId,
            "reviewerId": reviewerId,
            "rating": rating,
            "comment": comment ?? ""
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            return Fail(error: ReviewError.invalidParameters).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { response in
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(Review.self, from: response.data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

