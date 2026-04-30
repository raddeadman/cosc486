import SwiftUI

struct MyListingsView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProductViewModel()

    private var currentUserId: String {
        authViewModel.currentUser?.id ?? ""
    }

    private var myProducts: [Product] {
        viewModel.productsForSeller(userId: currentUserId)
    }

    var body: some View {
        Group {
            if myProducts.isEmpty {
                ContentUnavailableView("No Listings", systemImage: "shippingbox")
            } else {
                List(myProducts) { product in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(product.title).font(.headline)
                            Spacer()
                            Text(product.isAvailable ? "Available" : "Sold")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(product.isAvailable ? .green.opacity(0.2) : .red.opacity(0.2))
                                .clipShape(Capsule())
                        }

                        Text(product.price.formattedPrice)
                            .font(.subheadline.weight(.semibold))

                        Button(product.isAvailable ? "Mark as Sold" : "Mark as Available") {
                            viewModel.updateAvailability(
                                product: product,
                                isAvailable: !product.isAvailable,
                                userId: currentUserId
                            )
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("My Listings")
        .onAppear {
            viewModel.fetchProducts()
        }
    }
}
