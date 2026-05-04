import SwiftUI
import Combine

struct ProfileView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var receivedReviews: [Review] = []
    @State private var reviewsError: String?
    @State private var isLoadingReviews = false
    @State private var reviewsFetch: AnyCancellable?

    private let reviewService = ReviewService()

    var body: some View {
        List {
            Section {
                HStack(alignment: .center, spacing: 16) {
                    profileAvatar
                        .frame(width: 72, height: 72)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 6) {
                        Text(authViewModel.currentUser?.name ?? "Guest")
                            .font(.title3.weight(.semibold))
                        Text(authViewModel.currentUser?.email ?? "—")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Average rating: \((authViewModel.currentUser?.ratingAverage ?? 0).formatted(.number.precision(.fractionLength(1))))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section {
                NavigationLink {
                    EditProfileView()
                        .environmentObject(authViewModel)
                } label: {
                    Label("Edit profile", systemImage: "pencil")
                }
            }

            Section("Reviews about you") {
                if isLoadingReviews && receivedReviews.isEmpty {
                    ProgressView("Loading…")
                } else if let reviewsError, receivedReviews.isEmpty {
                    Text(reviewsError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                } else if receivedReviews.isEmpty {
                    Text("No reviews yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(receivedReviews) { review in
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
                                    .font(.subheadline)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section("Actions") {
                NavigationLink("My Listings") { MyListingsView() }
                NavigationLink("Favorites") { FavoritesView() }
                Button("Logout", role: .destructive) { authViewModel.logout() }
            }
        }
        .navigationTitle("Profile")
        .onAppear {
            fetchReceivedReviews()
        }
        .onChange(of: authViewModel.currentUser?.id) { _, _ in
            fetchReceivedReviews()
        }
    }

    @ViewBuilder
    private var profileAvatar: some View {
        let urlString = authViewModel.currentUser?.profileImageUrl ?? ""
        if let url = URL(string: urlString), !urlString.isEmpty {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure, .empty:
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.secondary)
                @unknown default:
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.secondary)
        }
    }

    private func fetchReceivedReviews() {
        guard let sellerId = authViewModel.currentUser?.id, !sellerId.isEmpty else {
            receivedReviews = []
            return
        }
        reviewsFetch?.cancel()
        isLoadingReviews = true
        reviewsError = nil
        reviewsFetch = reviewService.fetchReviews(sellerId: sellerId)
            .sink { completion in
                isLoadingReviews = false
                if case .failure(let err) = completion {
                    reviewsError = err.localizedDescription
                    receivedReviews = []
                }
            } receiveValue: { list in
                receivedReviews = list
            }
    }
}
