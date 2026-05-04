import Foundation

struct User: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let email: String
    let profileImageUrl: String
    let ratingAverage: Double
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, email, profileImageUrl, ratingAverage, createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)
        profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl) ?? ""
        ratingAverage = try container.decodeIfPresent(Double.self, forKey: .ratingAverage) ?? 0.0
        if let date = try? container.decode(Date.self, forKey: .createdAt) {
            createdAt = date
        } else if let stringValue = try? container.decode(String.self, forKey: .createdAt),
                  let parsedDate = ISO8601DateFormatter().date(from: stringValue) {
            createdAt = parsedDate
        } else {
            createdAt = Date()
        }
    }
}
