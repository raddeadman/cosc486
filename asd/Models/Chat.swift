// MARK: - Chat Model
// Represents a chat conversation between buyer and seller for a specific product

import Foundation

struct Chat: Identifiable, Codable, Hashable {
    let id: String
    let buyerId: String
    let sellerId: String
    let productId: String
    let participantIds: [String]
    let lastMessage: String?
    let createdAt: Date
    let updatedAt: Date
    /// `open` or `resolved`; missing from API treated as open.
    let chatStatus: String?
    let resolvedAt: Date?
    let resolvedBy: String?

    enum CodingKeys: String, CodingKey {
        case id, buyerId, sellerId, productId, participantIds, lastMessage, createdAt, updatedAt
        case chatStatus, resolvedAt, resolvedBy
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        buyerId = try container.decodeIfPresent(String.self, forKey: .buyerId) ?? ""
        sellerId = try container.decodeIfPresent(String.self, forKey: .sellerId) ?? ""
        productId = try container.decodeIfPresent(String.self, forKey: .productId) ?? ""
        participantIds = try container.decodeIfPresent([String].self, forKey: .participantIds) ?? []
        lastMessage = try container.decodeIfPresent(String.self, forKey: .lastMessage)
        chatStatus = try container.decodeIfPresent(String.self, forKey: .chatStatus)
        resolvedBy = try container.decodeIfPresent(String.self, forKey: .resolvedBy)

        if let createdAtDate = try? container.decode(Date.self, forKey: .createdAt) {
            createdAt = createdAtDate
        } else if let createdAtString = try? container.decode(String.self, forKey: .createdAt),
                  let parsedCreatedAt = ISO8601DateFormatter().date(from: createdAtString) {
            createdAt = parsedCreatedAt
        } else {
            createdAt = Date()
        }

        if let updatedAtDate = try? container.decode(Date.self, forKey: .updatedAt) {
            updatedAt = updatedAtDate
        } else if let updatedAtString = try? container.decode(String.self, forKey: .updatedAt),
                  let parsedUpdatedAt = ISO8601DateFormatter().date(from: updatedAtString) {
            updatedAt = parsedUpdatedAt
        } else {
            updatedAt = createdAt
        }

        if let d = try? container.decode(Date.self, forKey: .resolvedAt) {
            resolvedAt = d
        } else if let s = try? container.decodeIfPresent(String.self, forKey: .resolvedAt),
                  let parsed = ISO8601DateFormatter().date(from: s) {
            resolvedAt = parsed
        } else {
            resolvedAt = nil
        }
    }
}