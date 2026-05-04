import SwiftUI

struct ProductReviewsScreen: View {
    let product: Product
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel = ReviewViewModel()
    @State private var showComposer = false

    private var currentUserId: String? { authViewModel.currentUser?.id }
    private var canReview: Bool {
        guard let uid = currentUserId else { return false }
        return uid != product.sellerId
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if viewModel.isLoading && viewModel.reviews.isEmpty {
                    ProgressView("Loading reviews…")
                } else if let err = viewModel.errorMessage, viewModel.reviews.isEmpty {
                    ContentUnavailableView("Couldn’t load reviews", systemImage: "star.slash", description: Text(err))
                } else {
                    List {
                        Section {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(String(format: "%.1f", product.reviewAverage))
                                        .font(.title.weight(.bold))
                                    RatingStarsView(
                                        rating: product.reviewAverage,
                                        isSelectable: false,
                                        selectedRating: .constant(0)
                                    )
                                    Text("\(product.reviewCount) review\(product.reviewCount == 1 ? "" : "s")")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .listRowBackground(Color.clear)
                        }

                        Section("Reviews") {
                            if viewModel.reviews.isEmpty {
                                Text("No reviews yet.")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(viewModel.reviews) { review in
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            RatingStarsView(
                                                rating: Double(review.rating),
                                                isSelectable: false,
                                                selectedRating: .constant(0)
                                            )
                                            Spacer()
                                            Text(review.timestamp, style: .date)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        if !review.comment.isEmpty {
                                            Text(review.comment)
                                                .font(.body)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }
            }

            if viewModel.hasLoadedOnce && (viewModel.isRefreshing || viewModel.isLoading) {
                ProgressView()
                    .scaleEffect(0.85)
                    .padding(12)
            }
        }
        .navigationTitle("Reviews")
        .toolbar {
            if canReview {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showComposer = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
        }
        .sheet(isPresented: $showComposer) {
            WriteProductReviewSheet(
                product: product,
                viewModel: viewModel,
                onDismiss: { showComposer = false }
            )
        }
        .onAppear {
            viewModel.fetchReviewsForProduct(productId: product.id)
        }
    }
}

private struct WriteProductReviewSheet: View {
    let product: Product
    @ObservedObject var viewModel: ReviewViewModel
    let onDismiss: () -> Void

    @State private var selectedRating = 5
    @State private var comment = ""
    @State private var submitCountBaseline = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("Your rating") {
                    RatingStarsView(
                        rating: Double(selectedRating),
                        isSelectable: true,
                        selectedRating: $selectedRating
                    )
                    .padding(.vertical, 4)
                }
                Section("Comment (optional)") {
                    TextField("Share your experience", text: $comment, axis: .vertical)
                        .lineLimit(4...10)
                }
                if let err = viewModel.errorMessage, !err.isEmpty {
                    Section {
                        Text(err)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Write a review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        viewModel.addReview(
                            productId: product.id,
                            sellerId: product.sellerId,
                            rating: selectedRating,
                            comment: comment.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                    }
                    .disabled(viewModel.isSubmitting || selectedRating < 1)
                    .opacity(viewModel.isSubmitting ? 0.5 : 1)
                }
            }
            .onAppear {
                viewModel.clearError()
                submitCountBaseline = viewModel.submitSucceededCount
            }
            .onChange(of: viewModel.submitSucceededCount) { _, newValue in
                if newValue > submitCountBaseline {
                    onDismiss()
                }
            }
        }
    }
}
