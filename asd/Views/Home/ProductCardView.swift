import SwiftUI

struct ProductCardView: View {
    let product: Product

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(.gray.opacity(0.2))
                .frame(width: 70, height: 70)
                .overlay(Image(systemName: "photo"))

            VStack(alignment: .leading, spacing: 4) {
                Text(product.title).font(.headline)
                Text(product.category).font(.caption).foregroundStyle(.secondary)
                Text(product.locationName).font(.caption2).foregroundStyle(.secondary)
                HStack {
                    Text(product.price.formattedPrice)
                        .fontWeight(.semibold)
                    Spacer()
                    RatingStarsView(rating: product.rating, isSelectable: false, selectedRating: .constant(0))
                }
            }
        }
    }
}
