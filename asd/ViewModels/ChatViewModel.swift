import Foundation
import Combine

final class ChatViewModel: ObservableObject {
    @Published var chatSummaries: [String] = ["chat-1"]
    @Published var messages: [Message] = []

    private let chatService = ChatService()
    private var cancellables = Set<AnyCancellable>()

    func fetchChats() {
        chatService.fetchChats()
            .sink { completion in
                // Handle completion if needed
            } receiveValue: { chats in
                self.chatSummaries = chats.map { $0.id }
            }
            .store(in: &cancellables)
    }

    func fetchMessages(chatId: String) {
        chatService.fetchMessages(chatId: chatId)
            .sink { completion in
                // Handle completion if needed
            } receiveValue: { messages in
                self.messages = messages
            }
            .store(in: &cancellables)
    }

    func sendMessage(text: String, chatId: String) {
        guard !text.isEmpty else { return }
        chatService.sendMessage(text: text, chatId: chatId)
            .sink { completion in
                // Handle completion if needed
            } receiveValue: { _ in
                self.fetchMessages(chatId: chatId)
            }
            .store(in: &cancellables)
    }
}

