import SwiftUI

struct ChatDetailView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    let chatId: String
    let product: Product?
    let productId: String?
    let sellerId: String?
    let buyerId: String?
    let initialChatStatus: String?
    let currentUserId: String?

    @StateObject private var viewModel = ChatViewModel()
    @State private var messageText = ""

    init(
        chatId: String,
        product: Product? = nil,
        productId: String? = nil,
        sellerId: String? = nil,
        buyerId: String? = nil,
        chatStatus: String? = nil,
        currentUserId: String? = nil
    ) {
        self.chatId = chatId
        self.product = product
        self.productId = productId ?? product?.id
        self.sellerId = sellerId ?? product?.sellerId
        self.buyerId = buyerId
        self.initialChatStatus = chatStatus
        self.currentUserId = currentUserId
    }

    private var displayProduct: Product? {
        product ?? viewModel.detailProduct
    }

    private var effectiveChatStatus: String {
        (viewModel.detailChatStatus ?? initialChatStatus ?? "open").lowercased()
    }

    private var isResolved: Bool {
        effectiveChatStatus == "resolved"
    }

    private var isCurrentUserSeller: Bool {
        guard let currentUserId, let sellerId, !sellerId.isEmpty else { return false }
        return currentUserId == sellerId
    }

    private var isCurrentUserBuyer: Bool {
        guard let currentUserId, let buyerId, !buyerId.isEmpty else { return false }
        return currentUserId == buyerId
    }

    private var resolvedProductId: String? {
        displayProduct?.id ?? (productId.flatMap { $0.isEmpty ? nil : $0 })
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                productHeader

                if isResolved {
                    VStack(spacing: 10) {
                        Label("This chat is resolved. Messaging is disabled.", systemImage: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color(.secondarySystemBackground))

                        if isCurrentUserBuyer,
                           let p = displayProduct,
                           !viewModel.buyerHasReviewedThisProduct {
                            NavigationLink {
                                ProductReviewsScreen(product: p)
                                    .environmentObject(authViewModel)
                            } label: {
                                Label("Review product", systemImage: "star.bubble")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.horizontal)
                        }
                    }
                }

                Group {
                    if viewModel.isLoadingMessages && viewModel.messages.isEmpty {
                        ProgressView("Loading messages...")
                            .frame(maxHeight: .infinity)
                    } else if let error = viewModel.messageErrorMessage, viewModel.messages.isEmpty {
                        ContentUnavailableView(
                            "Failed to Load Messages",
                            systemImage: "exclamationmark.bubble",
                            description: Text(error)
                        )
                    } else {
                        ScrollViewReader { proxy in
                            List(viewModel.messages) { message in
                                messageRow(message)
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .id(message.id)
                            }
                            .listStyle(.plain)
                            .onChange(of: viewModel.messages.count) { _, _ in
                                if let last = viewModel.messages.last {
                                    withAnimation {
                                        proxy.scrollTo(last.id, anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: .infinity)

                composer
            }

            if viewModel.hasLoadedMessagesOnce && (viewModel.isRefreshingMessages || viewModel.isLoadingMessages) {
                ProgressView()
                    .scaleEffect(0.85)
                    .padding(12)
            }
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.detailChatStatus = initialChatStatus
            if product == nil, let pid = productId, !pid.isEmpty {
                viewModel.loadDetailProduct(productId: pid)
            }
            viewModel.fetchMessages(chatId: chatId)
            refreshReviewEligibility()
        }
        .onChange(of: viewModel.detailChatStatus) { _, _ in
            refreshReviewEligibility()
        }
        .onChange(of: viewModel.detailProduct?.id) { _, _ in
            refreshReviewEligibility()
        }
    }

    private func refreshReviewEligibility() {
        viewModel.refreshBuyerReviewState(
            productId: resolvedProductId,
            buyerId: buyerId,
            currentUserId: currentUserId
        )
    }

    @ViewBuilder
    private var productHeader: some View {
        if let p = displayProduct {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Product")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(p.title)
                            .font(.headline)
                            .lineLimit(2)
                        Text(p.price.formattedPrice)
                            .font(.subheadline.weight(.semibold))
                        Text("Seller: \(p.sellerName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    NavigationLink {
                        ProductDetailView(product: p)
                    } label: {
                        Text("View")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.borderedProminent)
                }

                if isCurrentUserSeller, !isResolved {
                    Button {
                        viewModel.resolveChat(chatId: chatId)
                    } label: {
                        if viewModel.isResolvingChat {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Label("Mark chat resolved (sold)", systemImage: "checkmark.circle")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isResolvingChat)
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            .padding(.top, 8)
        } else if let pid = productId, !pid.isEmpty {
            HStack {
                ProgressView()
                    .scaleEffect(0.9)
                Text("Loading product…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    @ViewBuilder
    private func messageRow(_ message: Message) -> some View {
        let isSender = message.senderId == currentUserId
        HStack(alignment: .bottom, spacing: 8) {
            if isSender { Spacer(minLength: 48) }
            Text(message.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .foregroundStyle(isSender ? Color.white : Color.primary)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSender ? Color.accentColor : Color(.secondarySystemFill))
                )
            if message.isPending {
                ProgressView()
                    .scaleEffect(0.85)
            }
            if !isSender { Spacer(minLength: 48) }
        }
    }

    private var composer: some View {
        VStack(spacing: 6) {
            if let error = viewModel.messageErrorMessage, !error.isEmpty, !viewModel.messages.isEmpty {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack {
                TextField("Message", text: $messageText)
                    .textFieldStyle(.roundedBorder)
                Button("Send") {
                    viewModel.sendMessage(text: messageText, chatId: chatId, currentUserId: currentUserId)
                    messageText = ""
                }
                .disabled(messageText.isEmpty || viewModel.isSendingMessage || isResolved)
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
}
