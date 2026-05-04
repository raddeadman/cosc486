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

    init(id: String, name: String, email: String, profileImageUrl: String, ratingAverage: Double, createdAt: Date) {
        self.id = id
        self.name = name
        self.email = email
        self.profileImageUrl = profileImageUrl
        self.ratingAverage = ratingAverage
        self.createdAt = createdAt
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

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(email, forKey: .email)
        try container.encode(profileImageUrl, forKey: .profileImageUrl)
        try container.encode(ratingAverage, forKey: .ratingAverage)
        try container.encode(createdAt, forKey: .createdAt)
    }
}
