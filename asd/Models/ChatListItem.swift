import Foundation

struct ChatListItem: Identifiable, Hashable {
    let chatId: String
    let productId: String
    let productTitle: String
    let productImageUrl: String?
    let counterpartUserId: String
    let counterpartName: String
    let lastMessagePreview: String
    let updatedAt: Date

    var id: String { chatId }
}

