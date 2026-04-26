import SwiftUI
import MapKit

struct ProductDetailView: View {
    let product: Product

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

                PrimaryButton(title: "Contact Seller") {}
                PrimaryButton(title: "Add to Favorites") {}
            }
            .padding()
        }
        .navigationTitle("Details")
    }
}
