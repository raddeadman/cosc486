import SwiftUI

struct ProductCardView: View {
    let product: Product

    var body: some View {
        HStack(spacing: 12) {
            if let first = product.imageUrls.first, let url = URL(string: first), !first.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholderThumb
                    case .empty:
                        ProgressView()
                    @unknown default:
                        placeholderThumb
                    }
                }
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                placeholderThumb
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(product.title).font(.headline)
                Text(product.category).font(.caption).foregroundStyle(.secondary)
                Text(product.locationName).font(.caption2).foregroundStyle(.secondary)
                HStack {
                    Text(product.price.formattedPrice)
                        .fontWeight(.semibold)
                    Spacer()
                    if product.reviewCount > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                            Text(String(format: "%.1f", product.reviewAverage))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        RatingStarsView(rating: product.rating, isSelectable: false, selectedRating: .constant(0))
                    }
                }
            }
        }
    }

    private var placeholderThumb: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(.secondarySystemFill))
            .frame(width: 70, height: 70)
            .overlay {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
    }
}
