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
            if let err = viewModel.listingErrorMessage, myProducts.isEmpty {
                ContentUnavailableView("Couldn’t load listings", systemImage: "shippingbox", description: Text(err))
            } else if myProducts.isEmpty {
                ContentUnavailableView("No Listings", systemImage: "shippingbox")
            } else {
                List(myProducts) { product in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(product.title).font(.headline)
                            Spacer()
                            Text(product.isAvailable ? "Available" : "Unavailable")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(product.isAvailable ? .green.opacity(0.2) : .red.opacity(0.2))
                                .clipShape(Capsule())
                        }

                        Text(product.price.formattedPrice)
                            .font(.subheadline.weight(.semibold))

                        Button(product.isAvailable ? "Mark as unavailable" : "Mark as available") {
                            viewModel.updateAvailability(
                                product: product,
                                isAvailable: !product.isAvailable,
                                userId: currentUserId
                            )
                        }
                        .buttonStyle(.borderedProminent)

                        if let err = viewModel.listingErrorMessage {
                            Text(err)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("My Listings")
        .onAppear {
            viewModel.fetchMyListings()
        }
    }
}
