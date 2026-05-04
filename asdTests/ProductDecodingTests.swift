import XCTest
@testable import asd

final class ProductDecodingTests: XCTestCase {
    func testDecodeProductWithStringNumericFields() throws {
        let json = """
        {
          "id": "p1",
          "title": "Desk",
          "description": "Wood",
          "price": "99.5",
          "category": "Furniture",
          "imageUrls": [],
          "sellerId": "u1",
          "sellerName": "Sam",
          "locationName": "Manama",
          "latitude": "26.2",
          "longitude": "50.5",
          "rating": "4.5",
          "reviewAverage": "4.0",
          "reviewCount": "3",
          "isAvailable": true,
          "createdAt": "2026-01-15T10:00:00Z"
        }
        """
        let data = Data(json.utf8)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let product = try decoder.decode(Product.self, from: data)
        XCTAssertEqual(product.id, "p1")
        XCTAssertEqual(product.title, "Desk")
        XCTAssertEqual(product.price, 99.5, accuracy: 0.001)
        XCTAssertEqual(product.latitude, 26.2, accuracy: 0.001)
        XCTAssertEqual(product.longitude, 50.5, accuracy: 0.001)
        XCTAssertEqual(product.rating, 4.5, accuracy: 0.001)
        XCTAssertEqual(product.reviewAverage, 4.0, accuracy: 0.001)
        XCTAssertEqual(product.reviewCount, 3)
        XCTAssertTrue(product.isAvailable)
    }

    func testProductCoordinate() {
        let p = Product(
            id: "1",
            title: "t",
            description: "d",
            price: 1,
            category: "c",
            imageUrls: [],
            sellerId: "s",
            sellerName: "n",
            locationName: "l",
            latitude: 10,
            longitude: 20,
            rating: 0,
            isAvailable: true,
            createdAt: Date()
        )
        XCTAssertEqual(p.coordinate.latitude, 10, accuracy: 0.0001)
        XCTAssertEqual(p.coordinate.longitude, 20, accuracy: 0.0001)
    }
}
