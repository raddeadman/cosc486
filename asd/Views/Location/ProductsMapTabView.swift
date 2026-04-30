import SwiftUI
import MapKit

struct ProductsMapTabView: View {
    @StateObject private var viewModel = ProductViewModel()
    @StateObject private var locationViewModel = LocationViewModel()
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedProduct: Product?

    var body: some View {
        VStack(spacing: 12) {
            SearchBarView(text: $viewModel.searchText)
                .padding(.horizontal)

            Map(position: $position) {
                UserAnnotation()

                ForEach(viewModel.filteredProducts) { product in
                    Annotation(product.title, coordinate: product.coordinate) {
                        Button {
                            selectedProduct = product
                        } label: {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.red)
                                .background(.white, in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            .mapControls {
                MapUserLocationButton()
            }
        }
        .padding(.top, 8)
        .navigationTitle("Map")
        .navigationDestination(item: $selectedProduct) { product in
            ProductDetailView(product: product)
        }
        .onAppear {
            viewModel.fetchProducts()
            locationViewModel.requestPermission()
        }
    }
}
