import SwiftUI

struct ChatListView: View {
    @StateObject private var viewModel = ChatViewModel()

    var body: some View {
        List(viewModel.chatSummaries, id: \.self) { chatId in
            NavigationLink(chatId) {
                ChatDetailView(chatId: chatId)
            }
        }
        .navigationTitle("Chats")
    }
}
