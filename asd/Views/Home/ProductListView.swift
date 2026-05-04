import SwiftUI

struct ProductListView: View {
    @StateObject private var viewModel = ProductViewModel()

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                HStack {
                    SearchBarView(text: $viewModel.searchText)
                        .padding(.horizontal)

                    Button {
                        viewModel.fetchProducts(isRefresh: true)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(.blue)
                    }
                    .padding(.trailing)
                }

                if viewModel.isLoading && viewModel.products.isEmpty {
                    ProgressView("Loading marketplace…")
                        .frame(maxHeight: .infinity)
                } else if viewModel.filteredProducts.isEmpty {
                    ContentUnavailableView(
                        "No products",
                        systemImage: "cube.box",
                        description: Text("Try another search or pull to refresh.")
                    )
                    .frame(maxHeight: .infinity)
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

            if viewModel.hasLoadedOnce && (viewModel.isRefreshing || viewModel.isLoading) && !viewModel.filteredProducts.isEmpty {
                ProgressView()
                    .scaleEffect(0.85)
                    .padding(12)
            }
        }
        .navigationTitle("Marketplace")
        .onAppear {
            viewModel.fetchProducts()
        }
    }
}
