import Foundation

final class ReviewService {
    private var reviewStore: [Review] = []

    func addReview(_ review: Review) {
        reviewStore.append(review)
    }

    func fetchReviews(sellerId: String) -> [Review] {
        reviewStore.filter { $0.sellerId == sellerId }
    }
}
