import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel = FavoritesViewModel()
    @AppStorage("favoritesSwipeHintShown") private var swipeHintShown = false
    @State private var hintPulse = false

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.favoriteProducts.isEmpty {
                ProgressView("Loading favorites…")
            } else if let err = viewModel.errorMessage, viewModel.favoriteProducts.isEmpty {
                ContentUnavailableView("Couldn’t load favorites", systemImage: "heart.slash", description: Text(err))
            } else if viewModel.favoriteProducts.isEmpty {
                ContentUnavailableView("No Favorites", systemImage: "heart.slash")
            } else {
                List(viewModel.favoriteProducts) { product in
                    NavigationLink {
                        ProductDetailView(product: product)
                    } label: {
                        ProductCardView(product: product)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.removeFavorite(product)
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("Favorites")
        .overlay(alignment: .topTrailing) {
            if viewModel.hasLoadedOnce && viewModel.isLoading && !viewModel.favoriteProducts.isEmpty {
                ProgressView()
                    .scaleEffect(0.85)
                    .padding(12)
            }
        }
        .overlay(alignment: .bottom) {
            if !viewModel.favoriteProducts.isEmpty && !swipeHintShown {
                Text("Swipe left on a row to remove")
                    .font(.caption)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(.bottom, 12)
                    .offset(x: hintPulse ? -6 : 6)
                    .animation(.easeInOut(duration: 0.9).repeatCount(3, autoreverses: true), value: hintPulse)
                    .task {
                        hintPulse = true
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        swipeHintShown = true
                    }
            }
        }
        .onAppear {
            viewModel.setCurrentUserId(authViewModel.currentUser?.id)
        }
        .onChange(of: authViewModel.currentUser?.id) { _, newUserId in
            viewModel.setCurrentUserId(newUserId)
        }
    }
}
