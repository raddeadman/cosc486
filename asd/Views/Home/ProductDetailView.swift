import SwiftUI
import MapKit

struct ProductDetailView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    let product: Product
    @State private var openChat = false
    @State private var targetChatId = ""
    private let chatService = ChatService()

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
                    // API placeholder:
                    // let chatId = try await chatService.getOrCreateChat(
                    //   buyerId: currentUserId,
                    //   sellerId: product.sellerId,
                    //   productId: product.id
                    // )
                    // targetChatId = chatId
                    targetChatId = chatService.getOrCreateChat(
                        buyerId: currentUserId,
                        sellerId: product.sellerId,
                        productId: product.id
                    )
                    openChat = true
                }
                PrimaryButton(title: "Add to Favorites") {}
            }
            .padding()
        }
        .navigationTitle("Details")
        .navigationDestination(isPresented: $openChat) {
            ChatDetailView(chatId: targetChatId, product: product, currentUserId: currentUserId)
        }
    }
}
