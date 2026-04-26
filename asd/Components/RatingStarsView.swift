import SwiftUI

struct RatingStarsView: View {
    let rating: Double
    let isSelectable: Bool
    @Binding var selectedRating: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: starName(for: index))
                    .foregroundStyle(.yellow)
                    .onTapGesture {
                        guard isSelectable else { return }
                        selectedRating = index
                    }
            }
        }
    }

    private func starName(for index: Int) -> String {
        if isSelectable {
            return index <= selectedRating ? "star.fill" : "star"
        }
        return Double(index) <= rating.rounded() ? "star.fill" : "star"
    }
}
