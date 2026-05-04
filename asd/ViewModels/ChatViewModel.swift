import Foundation
import Combine

final class ChatViewModel: ObservableObject {
    @Published var chatListItems: [ChatListItem] = []
    @Published var messages: [Message] = []
    @Published var isLoadingChats = false
    @Published var isLoadingMessages = false
    @Published var isSendingMessage = false
    @Published var listErrorMessage: String?
    @Published var messageErrorMessage: String?

    private let chatService = ChatService()
    private let productService = ProductService()
    private let authService = AuthService()
    private var cancellables = Set<AnyCancellable>()
    private var productCache: [String: Product] = [:]
    private var userNameCache: [String: String] = [:]

    func fetchChats(currentUserId: String?) {
        isLoadingChats = true
        listErrorMessage = nil
        guard let currentUserId, !currentUserId.isEmpty else {
            chatListItems = []
            isLoadingChats = false
            listErrorMessage = "You must be signed in to view chats."
            return
        }

        chatService.fetchChats()
            .sink { [weak self] completion in
                guard let self else { return }
                self.isLoadingChats = false
                if case .failure(let error) = completion {
                    self.chatListItems = []
                    self.listErrorMessage = error.localizedDescription
                }
            } receiveValue: { chats in
                self.composeChatListItems(from: chats, currentUserId: currentUserId)
            }
            .store(in: &cancellables)
    }

    private func composeChatListItems(from chats: [Chat], currentUserId: String) {
        loadProductsIfNeeded(for: chats.map(\.productId)) { [weak self] in
            guard let self else { return }

            let items: [ChatListItem] = chats.map { chat in
                let product = self.productCache[chat.productId]
                let counterpartUserId = chat.buyerId == currentUserId ? chat.sellerId : chat.buyerId
                let counterpartName: String

                if chat.buyerId == currentUserId {
                    counterpartName = product?.sellerName.isEmpty == false ? product?.sellerName ?? "Unknown user" : "Unknown user"
                } else {
                    counterpartName = self.userNameCache[counterpartUserId] ?? "Buyer"
                }

                let lastMessage = chat.lastMessage?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return ChatListItem(
                    chatId: chat.id,
                    productId: chat.productId,
                    productTitle: product?.title.isEmpty == false ? product?.title ?? "Unknown product" : "Unknown product",
                    productImageUrl: product?.imageUrls.first,
                    counterpartUserId: counterpartUserId,
                    counterpartName: counterpartName,
                    lastMessagePreview: lastMessage.isEmpty ? "No messages yet" : lastMessage,
                    updatedAt: chat.updatedAt
                )
            }

            self.chatListItems = items.sorted(by: { $0.updatedAt > $1.updatedAt })

            for chat in chats where chat.buyerId != currentUserId {
                let counterpartUserId = chat.buyerId
                guard self.userNameCache[counterpartUserId] == nil, !counterpartUserId.isEmpty else { continue }
                self.fetchAndCacheUserName(userId: counterpartUserId, chatId: chat.id)
            }
        }
    }

    private func loadProductsIfNeeded(for productIds: [String], completion: @escaping () -> Void) {
        let missingIds = Set(productIds).filter { productCache[$0] == nil }
        guard !missingIds.isEmpty else {
            completion()
            return
        }

        productService.fetchProducts()
            .sink { [weak self] completionState in
                if case .failure(let error) = completionState {
                    self?.listErrorMessage = error.localizedDescription
                }
                completion()
            } receiveValue: { [weak self] products in
                guard let self else { return }
                for product in products where missingIds.contains(product.id) {
                    self.productCache[product.id] = product
                }
            }
            .store(in: &cancellables)
    }

    private func fetchAndCacheUserName(userId: String, chatId: String) {
        authService.fetchUserProfile(uid: userId)
            .sink { [weak self] completion in
                guard let self else { return }
                if case .failure = completion {
                    self.userNameCache[userId] = "Buyer"
                }
            } receiveValue: { [weak self] user in
                guard let self else { return }
                self.userNameCache[userId] = user.name.isEmpty ? "Buyer" : user.name
                self.updateCounterpartName(chatId: chatId, name: self.userNameCache[userId] ?? "Buyer")
            }
            .store(in: &cancellables)
    }

    private func updateCounterpartName(chatId: String, name: String) {
        guard let index = chatListItems.firstIndex(where: { $0.chatId == chatId }) else { return }
        let existing = chatListItems[index]
        chatListItems[index] = ChatListItem(
            chatId: existing.chatId,
            productId: existing.productId,
            productTitle: existing.productTitle,
            productImageUrl: existing.productImageUrl,
            counterpartUserId: existing.counterpartUserId,
            counterpartName: name,
            lastMessagePreview: existing.lastMessagePreview,
            updatedAt: existing.updatedAt
        )
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

