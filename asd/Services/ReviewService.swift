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
    private let baseURL = "https://api.example.com/v1"

    // MARK: - Fetch Reviews

    func fetchReviews(sellerId: String) -> AnyPublisher<[Review], Error> {
        guard !sellerId.isEmpty else {
            return Fail(error: ReviewError.invalidParameters).eraseToAnyPublisher()
        }

        let urlString = "\(baseURL)/reviews?sellerId=\(sellerId)"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "GET"

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap(\.response)
            .decode(type: [Review].self, decoder: JSONDecoder())
            .receive(on: DispatchQuery.main)
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

        let urlString = "\(baseURL)/reviews"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

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
            .tryMap(\.response)
            .decode(type: Review.self, decoder: JSONDecoder())
            .receive(on: DispatchQuery.main)
            .eraseToAnyPublisher()
    }
}
