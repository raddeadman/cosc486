import SwiftUI

struct ChatListView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel = ChatViewModel()

    var body: some View {
        Group {
            if viewModel.isLoadingChats && viewModel.chatSummaries.isEmpty {
                ProgressView("Loading chats...")
            } else if let error = viewModel.listErrorMessage, viewModel.chatSummaries.isEmpty {
                ContentUnavailableView("Failed to Load Chats", systemImage: "exclamationmark.bubble", description: Text(error))
            } else if viewModel.chatSummaries.isEmpty {
                ContentUnavailableView("No Chats Yet", systemImage: "message")
            } else {
                List(viewModel.chatSummaries, id: \.self) { chatId in
                    NavigationLink(chatId) {
                        ChatDetailView(chatId: chatId, currentUserId: authViewModel.currentUser?.id)
                    }
                }
            }
        }
        .navigationTitle("Chats")
        .task {
            viewModel.fetchChats()
        }
    }
}
