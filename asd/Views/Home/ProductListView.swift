import SwiftUI

struct ProductListView: View {
    @StateObject private var viewModel = ProductViewModel()

    var body: some View {
        VStack {
            SearchBarView(text: $viewModel.searchText)
                .padding(.horizontal)

            List(viewModel.filteredProducts) { product in
                NavigationLink {
                    ProductDetailView(product: product)
                } label: {
                    ProductCardView(product: product)
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("Marketplace")
    }
}
