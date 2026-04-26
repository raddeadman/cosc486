import Foundation

final class ChatService {
    private var messagesStore: [Message] = [
        Message(id: UUID().uuidString, chatId: "chat-1", senderId: "other-user", receiverId: "current-user", text: "Is this available?", timestamp: .now)
    ]

    func fetchChats() -> [String] {
        ["chat-1"]
    }

    func fetchMessages(chatId: String) -> [Message] {
        messagesStore.filter { $0.chatId == chatId }
    }

    func sendMessage(text: String, chatId: String) {
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
