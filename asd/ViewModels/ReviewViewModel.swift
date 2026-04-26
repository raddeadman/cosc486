import Foundation
import Combine

final class ReviewViewModel: ObservableObject {
    @Published var reviews: [Review] = []

    private let reviewService = ReviewService()

    func addReview(_ review: Review) {
        reviewService.addReview(review)
        fetchReviews(sellerId: review.sellerId)
    }

    func fetchReviews(sellerId: String) {
        reviews = reviewService.fetchReviews(sellerId: sellerId)
    }

    func averageRating(for sellerId: String) -> Double {
        let sellerReviews = reviews.filter { $0.sellerId == sellerId }
        guard !sellerReviews.isEmpty else { return 0 }
        let sum = sellerReviews.reduce(0) { $0 + Double($1.rating) }
        return sum / Double(sellerReviews.count)
    }
}
