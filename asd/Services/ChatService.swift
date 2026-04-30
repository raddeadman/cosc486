import Foundation

final class ChatService {
    private var messagesStore: [Message] = [
        Message(id: UUID().uuidString, chatId: "chat-1", senderId: "other-user", receiverId: "current-user", text: "Is this available?", timestamp: .now)
    ]

    func getOrCreateChat(buyerId: String, sellerId: String, productId: String) -> String {
        // API placeholder:
        // POST https://api.example.com/v1/chats
        // Body: { "buyerId": buyerId, "sellerId": sellerId, "productId": productId }
        // Response: { "id": "chat-...", "participantIds": [buyerId, sellerId], "productId": productId }
        // let (_, data) = try await URLSession.shared.data(for: request)
        // let chat = try JSONDecoder().decode(ChatSummary.self, from: data)
        // return chat.id
        let userA = min(buyerId, sellerId)
        let userB = max(buyerId, sellerId)
        return "chat-\(productId)-\(userA)-\(userB)"
    }

    func fetchChats() -> [String] {
        // API placeholder:
        // GET https://api.example.com/v1/chats
        // Response should include productId for product-scoped chat previews
        // let (data, _) = try await URLSession.shared.data(from: url)
        // return try JSONDecoder().decode([String].self, from: data)
        ["chat-1"]
    }

    func fetchMessages(chatId: String) -> [Message] {
        // API placeholder:
        // GET https://api.example.com/v1/chats/{chatId}/messages
        // let (data, _) = try await URLSession.shared.data(from: url)
        // return try JSONDecoder().decode([Message].self, from: data)
        messagesStore.filter { $0.chatId == chatId }
    }

    func sendMessage(text: String, chatId: String) {
        // API placeholder:
        // POST https://api.example.com/v1/chats/{chatId}/messages
        // Body: { "text": text }
        // let (_, _) = try await URLSession.shared.data(for: request)
        let message = Message(
            id: UUID().uuidString,
            chatId: chatId,
            senderId: "current-user",
            receiverId: "other-user",
            text: text,
            timestamp: .now
        )
        messagesStore.append(message)
    }
}
