import Foundation
import Combine

final class ReviewViewModel: ObservableObject {
    @Published var reviews: [Review] = []

    private let reviewService = ReviewService()
    private var cancellables = Set<AnyCancellable>()

    func addReview(_ review: Review) {
        reviewService.addReview(sellerId: review.sellerId, reviewerId: review.reviewerId, rating: review.rating, comment: review.comment)
            .sink { completion in
                // Handle completion if needed
            } receiveValue: { _ in
                self.fetchReviews(sellerId: review.sellerId)
            }
            .store(in: &cancellables)
    }

    func fetchReviews(sellerId: String) {
        reviewService.fetchReviews(sellerId: sellerId)
            .sink { completion in
                // Handle completion if needed
            } receiveValue: { reviews in
                self.reviews = reviews
            }
            .store(in: &cancellables)
    }

    func averageRating(for sellerId: String) -> Double {
        let sellerReviews = reviews.filter { $0.sellerId == sellerId }
        guard !sellerReviews.isEmpty else { return 0 }
        let sum = sellerReviews.reduce(0) { $0 + Double($1.rating) }
        return sum / Double(sellerReviews.count)
    }
}

