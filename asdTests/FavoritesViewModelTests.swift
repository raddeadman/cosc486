import XCTest
@testable import asd

final class FavoritesViewModelTests: XCTestCase {
    private func sampleProduct(id: String = "p1") -> Product {
        Product(
            id: id,
            title: "T",
            description: "D",
            price: 1,
            category: "C",
            imageUrls: [],
            sellerId: "s",
            sellerName: "N",
            locationName: "L",
            latitude: 0,
            longitude: 0,
            rating: 0,
            isAvailable: true,
            createdAt: Date()
        )
    }

    func testIsFavoriteFalseInitially() {
        let vm = FavoritesViewModel()
        XCTAssertFalse(vm.isFavorite(productId: "x"))
    }

    func testSetCurrentUserIdNilClearsState() {
        let vm = FavoritesViewModel()
        vm.favoriteProducts = [sampleProduct()]
        vm.hasLoadedOnce = true
        vm.setCurrentUserId(nil)
        XCTAssertTrue(vm.favoriteProducts.isEmpty)
        XCTAssertFalse(vm.hasLoadedOnce)
    }

    func testIsFavoriteTrueWhenProductInList() {
        let vm = FavoritesViewModel()
        vm.favoriteProducts = [sampleProduct(id: "abc")]
        XCTAssertTrue(vm.isFavorite(productId: "abc"))
    }
}
