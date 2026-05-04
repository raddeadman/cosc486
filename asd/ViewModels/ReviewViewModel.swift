import Foundation
import Combine

final class ReviewViewModel: ObservableObject {
    @Published var reviews: [Review] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var isSubmitting = false
    @Published var hasLoadedOnce = false
    @Published var errorMessage: String?
    /// Incremented after a review is successfully created (for UI dismiss).
    @Published private(set) var submitSucceededCount = 0

    func clearError() {
        errorMessage = nil
    }

    private let reviewService = ReviewService()
    private var cancellables = Set<AnyCancellable>()

    func fetchReviewsForSeller(sellerId: String) {
        isLoading = true
        errorMessage = nil
        reviewService.fetchReviews(sellerId: sellerId)
            .sink { [weak self] completion in
                guard let self else { return }
                self.isLoading = false
                if case .failure(let error) = completion {
                    self.errorMessage = error.localizedDescription
                    self.reviews = []
                }
            } receiveValue: { [weak self] reviews in
                guard let self else { return }
                self.reviews = reviews
                self.hasLoadedOnce = true
            }
            .store(in: &cancellables)
    }

    func fetchReviewsForProduct(productId: String, subtleRefresh: Bool = false) {
        if subtleRefresh && hasLoadedOnce && !reviews.isEmpty {
            isRefreshing = true
        } else {
            isLoading = true
        }
        errorMessage = nil
        reviewService.fetchProductReviews(productId: productId)
            .sink { [weak self] completion in
                guard let self else { return }
                self.isLoading = false
                self.isRefreshing = false
                if case .failure(let error) = completion {
                    self.errorMessage = error.localizedDescription
                    if !self.hasLoadedOnce {
                        self.reviews = []
                    }
                }
            } receiveValue: { [weak self] reviews in
                guard let self else { return }
                self.reviews = reviews
                self.hasLoadedOnce = true
            }
            .store(in: &cancellables)
    }

    func addReview(productId: String, sellerId: String, rating: Int, comment: String?) {
        let clamped = min(5, max(1, rating))
        isSubmitting = true
        errorMessage = nil
        reviewService.addReview(productId: productId, sellerId: sellerId, rating: clamped, comment: comment)
            .sink { [weak self] completion in
                guard let self else { return }
                self.isSubmitting = false
                if case .failure(let error) = completion {
                    self.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] _ in
                guard let self else { return }
                self.submitSucceededCount += 1
                self.fetchReviewsForProduct(productId: productId, subtleRefresh: true)
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
