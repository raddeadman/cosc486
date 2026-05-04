import Foundation
import Combine

final class ChatViewModel: ObservableObject {
    @Published var chatListItems: [ChatListItem] = []
    @Published var messages: [Message] = []
    @Published var isLoadingChats = false
    @Published var isLoadingMessages = false
    @Published var isRefreshingMessages = false
    @Published var isSendingMessage = false
    @Published var isResolvingChat = false
    @Published var hasLoadedMessagesOnce = false
    @Published var hasLoadedChatsOnce = false
    @Published var listErrorMessage: String?
    @Published var messageErrorMessage: String?
    @Published var detailProduct: Product?
    @Published var detailChatStatus: String?

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
                self.hasLoadedChatsOnce = true
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
                    updatedAt: chat.updatedAt,
                    sellerId: chat.sellerId,
                    buyerId: chat.buyerId,
                    chatStatus: chat.chatStatus
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
            updatedAt: existing.updatedAt,
            sellerId: existing.sellerId,
            buyerId: existing.buyerId,
            chatStatus: existing.chatStatus
        )
    }

    func fetchMessages(chatId: String, isRefresh: Bool = false) {
        if isRefresh && hasLoadedMessagesOnce && !messages.isEmpty {
            isRefreshingMessages = true
        } else {
            isLoadingMessages = true
        }
        messageErrorMessage = nil
        chatService.fetchMessages(chatId: chatId)
            .sink { [weak self] completion in
                guard let self else { return }
                self.isLoadingMessages = false
                self.isRefreshingMessages = false
                if case .failure(let error) = completion {
                    self.messages = []
                    self.messageErrorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] messages in
                guard let self else { return }
                self.messages = messages
                self.hasLoadedMessagesOnce = true
            }
            .store(in: &cancellables)
    }

    func loadDetailProduct(productId: String?) {
        guard let productId, !productId.isEmpty else {
            detailProduct = nil
            return
        }
        productService.fetchProduct(productId: productId)
            .sink { [weak self] completion in
                if case .failure = completion {
                    self?.detailProduct = nil
                }
            } receiveValue: { [weak self] product in
                self?.detailProduct = product
            }
            .store(in: &cancellables)
    }

    func resolveChat(chatId: String) {
        isResolvingChat = true
        messageErrorMessage = nil
        chatService.resolveChat(chatId: chatId)
            .sink { [weak self] completion in
                guard let self else { return }
                self.isResolvingChat = false
                if case .failure(let error) = completion {
                    self.messageErrorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] chat in
                guard let self else { return }
                self.detailChatStatus = chat.chatStatus ?? "resolved"
                if let idx = self.chatListItems.firstIndex(where: { $0.chatId == chat.id }) {
                    let e = self.chatListItems[idx]
                    self.chatListItems[idx] = ChatListItem(
                        chatId: e.chatId,
                        productId: e.productId,
                        productTitle: e.productTitle,
                        productImageUrl: e.productImageUrl,
                        counterpartUserId: e.counterpartUserId,
                        counterpartName: e.counterpartName,
                        lastMessagePreview: e.lastMessagePreview,
                        updatedAt: e.updatedAt,
                        sellerId: e.sellerId,
                        buyerId: e.buyerId,
                        chatStatus: chat.chatStatus ?? "resolved"
                    )
                }
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
                self.fetchMessages(chatId: chatId, isRefresh: true)
            }
            .store(in: &cancellables)
    }
}

