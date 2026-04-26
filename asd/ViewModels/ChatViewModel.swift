import Foundation
import Combine

final class ChatViewModel: ObservableObject {
    @Published var chatSummaries: [String] = ["chat-1"]
    @Published var messages: [Message] = []

    private let chatService = ChatService()

    func fetchChats() {
        chatSummaries = chatService.fetchChats()
    }

    func fetchMessages(chatId: String) {
        messages = chatService.fetchMessages(chatId: chatId)
    }

    func sendMessage(text: String, chatId: String) {
        guard !text.isEmpty else { return }
        chatService.sendMessage(text: text, chatId: chatId)
        fetchMessages(chatId: chatId)
    }
}
