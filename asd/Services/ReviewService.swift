import Foundation

final class ReviewService {
    private var reviewStore: [Review] = []

    func addReview(_ review: Review) {
        // API placeholder:
        // POST https://api.example.com/v1/reviews
        // Body: { "sellerId": review.sellerId, "reviewerId": review.reviewerId, "rating": review.rating, "comment": review.comment }
        // let (_, _) = try await URLSession.shared.data(for: request)
        reviewStore.append(review)
    }

    func fetchReviews(sellerId: String) -> [Review] {
        // API placeholder:
        // GET https://api.example.com/v1/reviews?sellerId={sellerId}
        // let (data, _) = try await URLSession.shared.data(from: url)
        // return try JSONDecoder().decode([Review].self, from: data)
        reviewStore.filter { $0.sellerId == sellerId }
    }
}
