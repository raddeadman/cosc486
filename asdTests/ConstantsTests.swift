import XCTest
@testable import asd

final class ConstantsTests: XCTestCase {
    func testCategoriesIncludeAllAndElectronics() {
        XCTAssertTrue(Constants.categories.contains("All"))
        XCTAssertTrue(Constants.categories.contains("Electronics"))
    }

    func testDefaultMapCenter() {
        XCTAssertEqual(Constants.defaultMapLatitude, 26.2235, accuracy: 0.0001)
        XCTAssertEqual(Constants.defaultMapLongitude, 50.5876, accuracy: 0.0001)
    }

    func testCollectionNames() {
        XCTAssertEqual(Constants.Collections.products, "products")
        XCTAssertEqual(Constants.Collections.favorites, "favorites")
    }
}
