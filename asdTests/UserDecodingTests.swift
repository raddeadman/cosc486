import XCTest
@testable import asd

final class UserDecodingTests: XCTestCase {
    func testDecodeUserISO8601CreatedAt() throws {
        let json = """
        {
          "id": "u1",
          "name": "Alex",
          "email": "a@b.com",
          "profileImageUrl": "",
          "ratingAverage": 4.2,
          "createdAt": "2026-02-01T12:00:00Z"
        }
        """
        let data = Data(json.utf8)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let user = try decoder.decode(User.self, from: data)
        XCTAssertEqual(user.id, "u1")
        XCTAssertEqual(user.name, "Alex")
        XCTAssertEqual(user.ratingAverage, 4.2, accuracy: 0.001)
    }
}
