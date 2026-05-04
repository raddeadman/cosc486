import SwiftUI

struct ChatDetailView: View {
    let chatId: String
    let product: Product?
    let currentUserId: String?
    @StateObject private var viewModel = ChatViewModel()
    @State private var messageText = ""

    init(chatId: String, product: Product? = nil, currentUserId: String? = nil) {
        self.chatId = chatId
        self.product = product
        self.currentUserId = currentUserId
    }

    var body: some View {
        VStack {
            if let product {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Product preview")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(product.title)
                        .font(.headline)
                    Text(product.price.formattedPrice)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("Seller: \(product.sellerName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(.gray.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }

            if viewModel.isLoadingMessages && viewModel.messages.isEmpty {
                ProgressView("Loading messages...")
                    .frame(maxHeight: .infinity)
            } else if let error = viewModel.messageErrorMessage, viewModel.messages.isEmpty {
                ContentUnavailableView("Failed to Load Messages", systemImage: "exclamationmark.bubble", description: Text(error))
            } else {
                List(viewModel.messages) { message in
                    HStack {
                        if message.senderId == currentUserId { Spacer() }
                        Text(message.text)
                            .padding(10)
                            .background(.gray.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        if message.senderId != currentUserId { Spacer() }
                    }
                }
            }

            HStack {
                TextField("Message", text: $messageText)
                    .textFieldStyle(.roundedBorder)
                Button("Send") {
                    viewModel.sendMessage(text: messageText, chatId: chatId)
                    messageText = ""
                }
                .disabled(messageText.isEmpty || viewModel.isSendingMessage)
            }
            .padding()

            if let error = viewModel.messageErrorMessage, !error.isEmpty {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
        .navigationTitle("Chat")
        .onAppear { viewModel.fetchMessages(chatId: chatId) }
    }
}
