import SwiftUI

struct SearchBarView: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search products", text: $text)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
            }
        }
        .padding(10)
        .background(.gray.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
