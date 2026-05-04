import SwiftUI
import UIKit
import XCTest
@testable import asd

/// Lightweight “does the view compile and mount?” checks without third-party snapshot tools.
final class SwiftUIViewHostingTests: XCTestCase {
    func testSearchBarViewLoads() {
        var text = "query"
        let binding = Binding<String>(
            get: { text },
            set: { text = $0 }
        )
        let host = UIHostingController(rootView: SearchBarView(text: binding))
        host.loadViewIfNeeded()
        XCTAssertNotNil(host.view)
    }

    func testPrimaryButtonLoads() {
        let host = UIHostingController(
            rootView: PrimaryButton(title: "Submit", isLoading: false, action: {})
        )
        host.loadViewIfNeeded()
        XCTAssertNotNil(host.view)
    }

    func testRatingStarsViewLoads() {
        struct Harness: View {
            @State private var selected = 2
            var body: some View {
                RatingStarsView(rating: 3.7, isSelectable: true, selectedRating: $selected)
            }
        }
        let host = UIHostingController(rootView: Harness())
        host.loadViewIfNeeded()
        XCTAssertNotNil(host.view)
    }
}
