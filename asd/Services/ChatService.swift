import Foundation
import Combine

// MARK: - Chat Service
// Handles all chat-related operations with the backend API

enum ChatError: Error, LocalizedError {
    case invalidParameters
    case networkError(Error)
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidParameters:
            return "Invalid parameters provided"
        case .networkError(let error):
            return error.localizedDescription
        case .serverError(let message):
            return message
        }
    }
}

final class ChatService {
    private let baseURL = "https://us-central1-openmarketmobile.cloudfunctions.net"

    // MARK: - Get or Create Chat

    func getOrCreateChat(
        buyerId: String,
        sellerId: String,
        productId: String
    ) -> AnyPublisher<Chat, Error> {
        guard !buyerId.isEmpty, !sellerId.isEmpty, !productId.isEmpty else {
            return Fail(error: ChatError.invalidParameters).eraseToAnyPublisher()
        }

        let urlString = "\(baseURL)/getOrCreateChat"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = TokenManager.get() {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let requestBody: [String: Any] = [
            "buyerId": buyerId,
            "sellerId": sellerId,
            "productId": productId
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            return Fail(error: ChatError.invalidParameters).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { response in
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(Chat.self, from: response.data)
    }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Fetch Chats

    func fetchChats() -> AnyPublisher<[Chat], Error> {
        let urlString = "\(baseURL)/fetchChats"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "GET"

        if let token = TokenManager.get() {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { response in
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode([Chat].self, from: response.data)
    }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
}

    // MARK: - Fetch Messages

    func fetchMessages(chatId: String) -> AnyPublisher<[Message], Error> {
        guard !chatId.isEmpty else {
            return Fail(error: ChatError.invalidParameters).eraseToAnyPublisher()
        }

        var components = URLComponents(string: "\(baseURL)/fetchMessages")
        components?.queryItems = [URLQueryItem(name: "chatId", value: chatId)]

        guard let url = components?.url else {
            return Fail(error: ChatError.invalidParameters).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let token = TokenManager.get() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { response in
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode([Message].self, from: response.data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Send Message

    func sendMessage(text: String, chatId: String) -> AnyPublisher<Message, Error> {
        guard !text.isEmpty, !chatId.isEmpty else {
            return Fail(error: ChatError.invalidParameters).eraseToAnyPublisher()
        }

        let urlString = "\(baseURL)/sendMessage"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = TokenManager.get() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let requestBody: [String: Any] = [
            "chatId": chatId,
            "text": text
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            return Fail(error: ChatError.invalidParameters).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { response in
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(Message.self, from: response.data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

