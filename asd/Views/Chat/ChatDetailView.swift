import SwiftUI

struct ChatDetailView: View {
    let chatId: String
    @StateObject private var viewModel = ChatViewModel()
    @State private var messageText = ""

    var body: some View {
        VStack {
            Text("Product preview")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            List(viewModel.messages) { message in
                HStack {
                    if message.senderId == "current-user" { Spacer() }
                    Text(message.text)
                        .padding(10)
                        .background(.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    if message.senderId != "current-user" { Spacer() }
                }
            }

            HStack {
                TextField("Message", text: $messageText)
                    .textFieldStyle(.roundedBorder)
                Button("Send") {
                    viewModel.sendMessage(text: messageText, chatId: chatId)
                    messageText = ""
                }
                .disabled(messageText.isEmpty)
            }
            .padding()
        }
        .navigationTitle("Chat")
        .onAppear { viewModel.fetchMessages(chatId: chatId) }
    }
}
