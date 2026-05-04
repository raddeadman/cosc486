import SwiftUI

struct ChatListView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel = ChatViewModel()
    private let dateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    var body: some View {
        Group {
            if viewModel.isLoadingChats && viewModel.chatListItems.isEmpty {
                ProgressView("Loading chats...")
            } else if let error = viewModel.listErrorMessage, viewModel.chatListItems.isEmpty {
                ContentUnavailableView("Failed to Load Chats", systemImage: "exclamationmark.bubble", description: Text(error))
            } else if viewModel.chatListItems.isEmpty {
                ContentUnavailableView("No Chats Yet", systemImage: "message")
            } else {
                List(viewModel.chatListItems) { item in
                    NavigationLink {
                        ChatDetailView(chatId: item.chatId, currentUserId: authViewModel.currentUser?.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(item.productTitle)
                                    .font(.headline)
                                    .lineLimit(1)
                                Spacer()
                                Text(dateFormatter.localizedString(for: item.updatedAt, relativeTo: Date()))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(item.counterpartName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Text(item.lastMessagePreview)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Chats")
        .task {
            viewModel.fetchChats(currentUserId: authViewModel.currentUser?.id)
        }
    }
}
