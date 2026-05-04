import XCTest
@testable import asd

@MainActor
final class AddProductViewModelTests: XCTestCase {
    func testValidateFailsWhenFieldsEmpty() {
        let vm = AddProductViewModel()
        vm.title = ""
        vm.description = ""
        vm.priceText = ""
        vm.locationName = ""
        vm.latitude = nil
        vm.longitude = nil
        XCTAssertFalse(vm.validate())
    }

    func testValidateFailsWhenPriceNotNumeric() {
        let vm = AddProductViewModel()
        vm.title = "Item"
        vm.description = "Desc"
        vm.priceText = "abc"
        vm.locationName = "City"
        vm.latitude = 26.0
        vm.longitude = 50.0
        XCTAssertFalse(vm.validate())
    }

    func testValidateFailsWhenCoordinatesInvalid() {
        let vm = AddProductViewModel()
        vm.title = "Item"
        vm.description = "Desc"
        vm.priceText = "10"
        vm.locationName = "City"
        vm.latitude = 200
        vm.longitude = 50
        XCTAssertFalse(vm.validate())
    }

    func testValidateSucceedsWhenComplete() {
        let vm = AddProductViewModel()
        vm.title = " Chair "
        vm.description = " Used "
        vm.priceText = "25.5"
        vm.locationName = " Manama "
        vm.latitude = 26.2
        vm.longitude = 50.5
        XCTAssertTrue(vm.validate())
    }

    func testPinCoordinateNilWithoutLatLon() {
        let vm = AddProductViewModel()
        XCTAssertNil(vm.pinCoordinate)
    }

    func testPinCoordinateSetWhenLatLonPresent() {
        let vm = AddProductViewModel()
        vm.latitude = 1
        vm.longitude = 2
        XCTAssertEqual(vm.pinCoordinate?.latitude, 1, accuracy: 0.0001)
        XCTAssertEqual(vm.pinCoordinate?.longitude, 2, accuracy: 0.0001)
    }
}
