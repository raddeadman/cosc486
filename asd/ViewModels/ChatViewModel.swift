import Foundation
import Combine

final class ChatViewModel: ObservableObject {
    @Published var chatSummaries: [String] = []
    @Published var messages: [Message] = []
    @Published var isLoadingChats = false
    @Published var isLoadingMessages = false
    @Published var isSendingMessage = false
    @Published var listErrorMessage: String?
    @Published var messageErrorMessage: String?

    private let chatService = ChatService()
    private var cancellables = Set<AnyCancellable>()

    func fetchChats() {
        isLoadingChats = true
        listErrorMessage = nil
        chatService.fetchChats()
            .sink { [weak self] completion in
                guard let self else { return }
                self.isLoadingChats = false
                if case .failure(let error) = completion {
                    self.chatSummaries = []
                    self.listErrorMessage = error.localizedDescription
                }
            } receiveValue: { chats in
                self.chatSummaries = chats.map { $0.id }
            }
            .store(in: &cancellables)
    }

    func fetchMessages(chatId: String) {
        isLoadingMessages = true
        messageErrorMessage = nil
        chatService.fetchMessages(chatId: chatId)
            .sink { [weak self] completion in
                guard let self else { return }
                self.isLoadingMessages = false
                if case .failure(let error) = completion {
                    self.messages = []
                    self.messageErrorMessage = error.localizedDescription
                }
            } receiveValue: { messages in
                self.messages = messages
            }
            .store(in: &cancellables)
    }

    func sendMessage(text: String, chatId: String) {
        guard !text.isEmpty else { return }
        isSendingMessage = true
        messageErrorMessage = nil
        chatService.sendMessage(text: text, chatId: chatId)
            .sink { [weak self] completion in
                guard let self else { return }
                self.isSendingMessage = false
                if case .failure(let error) = completion {
                    self.messageErrorMessage = error.localizedDescription
                }
            } receiveValue: { _ in
                self.fetchMessages(chatId: chatId)
            }
            .store(in: &cancellables)
    }
}

