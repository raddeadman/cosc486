import Foundation

struct Message: Identifiable, Codable, Hashable {
    let id: String
    let chatId: String
    let senderId: String
    let receiverId: String  // Added to match backend response
    let text: String
    let createdAt: Date  // Changed from timestamp to createdAt to match backend
}

