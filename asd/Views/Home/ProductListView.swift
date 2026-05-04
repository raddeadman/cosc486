import SwiftUI

struct ProductListView: View {
    @StateObject private var viewModel = ProductViewModel()
    @State private var showRefreshIndicator = false

    var body: some View {
        VStack {
            HStack {
                SearchBarView(text: $viewModel.searchText)
                    .padding(.horizontal)

                Button(action: { refreshProducts() }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(.blue)
                }
                .padding(.trailing)
            }

            if viewModel.products.isEmpty && !showRefreshIndicator {
                VStack(spacing: 12) {
                    Image(systemName: "cube.box")
                        .font(.system(size: 48))
                        .foregroundStyle(.gray)
                    Text("No products available")
                        .foregroundStyle(.secondary)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            } else {
                List(viewModel.filteredProducts) { product in
                    NavigationLink {
                        ProductDetailView(product: product)
                    } label: {
                        ProductCardView(product: product)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Marketplace")
        .onAppear { viewModel.fetchProducts() }
    }

    private func refreshProducts() {
        showRefreshIndicator = true
        viewModel.fetchProducts()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showRefreshIndicator = false
        }
    }
}
