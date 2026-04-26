import SwiftUI

struct MyListingsView: View {
    @StateObject private var viewModel = ProductViewModel()

    var body: some View {
        List(viewModel.products) { product in
            VStack(alignment: .leading, spacing: 8) {
                Text(product.title).font(.headline)
                HStack {
                    Button("Edit") {}
                    Button("Delete", role: .destructive) {}
                    Button("Mark Sold") {}
                }
                .buttonStyle(.bordered)
            }
        }
        .navigationTitle("My Listings")
    }
}
