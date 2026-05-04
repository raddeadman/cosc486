import Foundation

struct Message: Identifiable, Codable, Hashable {
    let id: String
    let senderId: String
    let text: String
    let createdAt: Date
    let receiverId: String?
    let chatId: String?
    /// Local-only: optimistic message while send is in flight.
    var isPending: Bool

    enum CodingKeys: String, CodingKey {
        case id, senderId, text, createdAt, receiverId, chatId
    }

    init(
        id: String,
        senderId: String,
        text: String,
        createdAt: Date,
        receiverId: String? = nil,
        chatId: String? = nil,
        isPending: Bool = false
    ) {
        self.id = id
        self.senderId = senderId
        self.text = text
        self.createdAt = createdAt
        self.receiverId = receiverId
        self.chatId = chatId
        self.isPending = isPending
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        senderId = try container.decodeIfPresent(String.self, forKey: .senderId) ?? ""
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
        receiverId = try container.decodeIfPresent(String.self, forKey: .receiverId)
        chatId = try container.decodeIfPresent(String.self, forKey: .chatId)

        if let date = try? container.decode(Date.self, forKey: .createdAt) {
            createdAt = date
        } else if let stringValue = try? container.decode(String.self, forKey: .createdAt),
                  let parsedDate = ISO8601DateFormatter().date(from: stringValue) {
            createdAt = parsedDate
        } else {
            createdAt = Date()
        }
        isPending = false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(senderId, forKey: .senderId)
        try container.encode(text, forKey: .text)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(receiverId, forKey: .receiverId)
        try container.encodeIfPresent(chatId, forKey: .chatId)
    }
}
