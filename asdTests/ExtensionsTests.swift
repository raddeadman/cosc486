import XCTest
@testable import asd

final class ExtensionsTests: XCTestCase {
    func testFormattedDistanceMeters() {
        XCTAssertEqual(500.formattedDistance, "500 m")
        XCTAssertEqual(0.formattedDistance, "0 m")
    }

    func testFormattedDistanceKilometers() {
        XCTAssertEqual(1500.formattedDistance, "1.5 km")
    }

    func testFormattedPriceNonEmpty() {
        let s = (12.34).formattedPrice
        XCTAssertFalse(s.isEmpty)
        XCTAssertNotNil(s.rangeOfCharacter(from: .decimalDigits))
    }
}
