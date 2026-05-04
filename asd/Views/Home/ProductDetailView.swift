import SwiftUI
import Combine

struct ProductDetailView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    let product: Product

    @StateObject private var favoritesViewModel = FavoritesViewModel()
    @State private var openChat = false
    @State private var targetChatId = ""
    @State private var targetChatStatus: String?
    private let chatService = ChatService()
    @State private var cancellables: [AnyCancellable] = []

    private var currentUserId: String? {
        authViewModel.currentUser?.id
    }

    private var isFavorite: Bool {
        favoritesViewModel.isFavorite(productId: product.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !product.imageUrls.isEmpty {
                    TabView {
                        ForEach(product.imageUrls, id: \.self) { urlString in
                            if let url = URL(string: urlString), !urlString.isEmpty {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    case .failure:
                                        galleryPlaceholder
                                    case .empty:
                                        ProgressView()
                                    @unknown default:
                                        galleryPlaceholder
                                    }
                                }
                                .frame(height: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            } else {
                                galleryPlaceholder
                            }
                        }
                    }
                    .frame(height: 220)
                    .tabViewStyle(.page)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(product.title)
                        .font(.title2.weight(.bold))
                    Text(product.price.formattedPrice)
                        .font(.title3.weight(.semibold))
                    Text(product.category)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                detailCard(title: "Description") {
                    Text(product.description)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                detailCard(title: "Location") {
                    Text(product.locationName)
                        .font(.subheadline)
                    ProductMapView(product: product)
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                detailCard(title: "Seller") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(product.sellerName)
                                .font(.headline)
                            Text("Listing rating (legacy)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            RatingStarsView(rating: product.rating, isSelectable: false, selectedRating: .constant(0))
                        }
                        Spacer()
                    }
                }

                detailCard(title: "Reviews") {
                    NavigationLink {
                        ProductReviewsScreen(product: product)
                            .environmentObject(authViewModel)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                if product.reviewCount > 0 {
                                    HStack(spacing: 6) {
                                        Text(String(format: "%.1f", product.reviewAverage))
                                            .font(.title3.weight(.semibold))
                                        RatingStarsView(
                                            rating: product.reviewAverage,
                                            isSelectable: false,
                                            selectedRating: .constant(0)
                                        )
                                    }
                                    Text("\(product.reviewCount) review\(product.reviewCount == 1 ? "" : "s")")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("No reviews yet")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Text("Tap to view or write a review")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }

                VStack(spacing: 12) {
                    PrimaryButton(title: "Contact Seller") {
                        guard let currentUserId else { return }
                        let cancellable = chatService.getOrCreateChat(
                            buyerId: currentUserId,
                            sellerId: product.sellerId,
                            productId: product.id
                        )
                        .sink { completion in
                            if case let .failure(error) = completion {
                                print("Failed to get/create chat: \(error)")
                            }
                        } receiveValue: { chat in
                            targetChatId = chat.id
                            targetChatStatus = chat.chatStatus
                            openChat = true
                        }
                        cancellables.append(cancellable)
                    }
                    .disabled(currentUserId == nil)
                }
            }
            .padding()
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if currentUserId != nil {
                    Button {
                        toggleFavorite()
                    } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundStyle(isFavorite ? Color.red : Color.primary)
                    }
                    .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
                }
            }
        }
        .navigationDestination(isPresented: $openChat) {
            ChatDetailView(
                chatId: targetChatId,
                product: product,
                sellerId: product.sellerId,
                chatStatus: targetChatStatus,
                currentUserId: currentUserId
            )
        }
        .onAppear {
            favoritesViewModel.setCurrentUserId(authViewModel.currentUser?.id)
        }
        .onChange(of: authViewModel.currentUser?.id) { _, newId in
            favoritesViewModel.setCurrentUserId(newId)
        }
    }

    private func toggleFavorite() {
        if isFavorite {
            favoritesViewModel.removeFavorite(product)
        } else {
            favoritesViewModel.addFavorite(product)
        }
    }

    @ViewBuilder
    private func detailCard(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var galleryPlaceholder: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color(.secondarySystemFill))
            .frame(height: 220)
            .overlay {
                Image(systemName: "photo.on.rectangle")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
    }
}
