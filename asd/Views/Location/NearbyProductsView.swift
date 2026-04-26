import SwiftUI

struct NearbyProductsView: View {
    @StateObject private var viewModel = LocationViewModel()

    var body: some View {
        List(viewModel.nearbyProducts) { product in
            NavigationLink(product.title) {
                ProductDetailView(product: product)
            }
        }
        .navigationTitle("Nearby")
        .onAppear {
            viewModel.requestPermission()
            viewModel.loadNearbyProducts()
        }
    }
}
