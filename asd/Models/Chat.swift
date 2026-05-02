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
}