import XCTest
@testable import asd

final class RatingStarsFormatterTests: XCTestCase {
    func testSelectableUsesSelectedRating() {
        XCTAssertEqual(
            RatingStarsFormatter.symbolName(index: 1, rating: 0, isSelectable: true, selectedRating: 0),
            "star"
        )
        XCTAssertEqual(
            RatingStarsFormatter.symbolName(index: 3, rating: 0, isSelectable: true, selectedRating: 4),
            "star.fill"
        )
    }

    func testReadOnlyUsesRoundedRating() {
        XCTAssertEqual(
            RatingStarsFormatter.symbolName(index: 3, rating: 3.4, isSelectable: false, selectedRating: 0),
            "star.fill"
        )
        XCTAssertEqual(
            RatingStarsFormatter.symbolName(index: 4, rating: 3.4, isSelectable: false, selectedRating: 0),
            "star"
        )
    }
}
