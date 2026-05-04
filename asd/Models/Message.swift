import Foundation

struct Message: Identifiable, Codable, Hashable {
    let id: String
    let senderId: String
    let text: String
    let createdAt: Date
    let receiverId: String?
    let chatId: String?

    enum CodingKeys: String, CodingKey {
        case id, senderId, text, createdAt, receiverId, chatId
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
    }
}

