import Foundation

struct Review: Identifiable, Codable, Hashable {
    let id: String
    let reviewerId: String
    let sellerId: String
    let rating: Int
    let comment: String
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case id, reviewerId, sellerId, rating, comment, timestamp, createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        reviewerId = try container.decodeIfPresent(String.self, forKey: .reviewerId) ?? ""
        sellerId = try container.decodeIfPresent(String.self, forKey: .sellerId) ?? ""
        let ratingString = (try? container.decodeIfPresent(String.self, forKey: .rating)) ?? nil
        rating = (try? container.decode(Int.self, forKey: .rating)) ?? ratingString.flatMap { Int($0) } ?? 0
        comment = try container.decodeIfPresent(String.self, forKey: .comment) ?? ""

        if let date = try? container.decode(Date.self, forKey: .timestamp) {
            timestamp = date
        } else if let stringValue = try? container.decode(String.self, forKey: .timestamp),
                  let parsedDate = ISO8601DateFormatter().date(from: stringValue) {
            timestamp = parsedDate
        } else if let date = try? container.decode(Date.self, forKey: .createdAt) {
            timestamp = date
        } else if let stringValue = try? container.decode(String.self, forKey: .createdAt),
                  let parsedDate = ISO8601DateFormatter().date(from: stringValue) {
            timestamp = parsedDate
        } else {
            timestamp = Date()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(reviewerId, forKey: .reviewerId)
        try container.encode(sellerId, forKey: .sellerId)
        try container.encode(rating, forKey: .rating)
        try container.encode(comment, forKey: .comment)
        try container.encode(timestamp, forKey: .timestamp)
    }
}
