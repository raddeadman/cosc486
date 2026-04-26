import Foundation

struct Message: Identifiable, Codable, Hashable {
    let id: String
    let chatId: String
    let senderId: String
    let receiverId: String
    let text: String
    let timestamp: Date
}
