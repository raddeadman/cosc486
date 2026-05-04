import SwiftUI
import MapKit
import Combine

struct ProductDetailView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    let product: Product
    @State private var openChat = false
    @State private var targetChatId = ""
    private let chatService = ChatService()
    @State private var cancellables: [AnyCancellable] = []

    private var currentUserId: String {
        authViewModel.currentUser?.id ?? "current-user"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                TabView {
                    ForEach(product.imageUrls, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.gray.opacity(0.2))
                            .frame(height: 220)
                            .overlay(Image(systemName: "photo.on.rectangle"))
                    }
                }
                .frame(height: 220)
                .tabViewStyle(.page)

                Text(product.title).font(.title2.bold())
                Text(product.description)
                Text(product.price.formattedPrice).font(.title3.weight(.semibold))
                Text("Category: \(product.category)")
                Text("Seller: \(product.sellerName)")

                RatingStarsView(rating: product.rating, isSelectable: false, selectedRating: .constant(0))

                ProductMapView(product: product)
                    .frame(height: 220)

                PrimaryButton(title: "Contact Seller") {
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
                        openChat = true
                    }
                    cancellables.append(cancellable)
                }
                PrimaryButton(title: "Add to Favorites") {
                    let favService = FavoritesService()
                    let cancellable = favService.addFavorite(productId: product.id, userId: currentUserId)
                        .sink { completion in
                            if case let .failure(error) = completion {
                                print("Failed to add favorite: \(error)")
                            }
                        } receiveValue: { success in
                            print("Added favorite: \(success)")
                        }
                    cancellables.append(cancellable)
                }
            }
            .padding()
        }
        .navigationTitle("Details")
        .navigationDestination(isPresented: $openChat) {
            ChatDetailView(chatId: targetChatId, product: product, currentUserId: currentUserId)
        }
    }
}
