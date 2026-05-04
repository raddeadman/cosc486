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
    
    private struct APIErrorResponse: Decodable {
        let error: String
    }

    private func validatedData(
        from output: URLSession.DataTaskPublisher.Output,
        successCodes: Set<Int>
    ) throws -> Data {
        guard let httpResponse = output.response as? HTTPURLResponse else {
            throw ChatError.serverError("Invalid server response")
        }

        if successCodes.contains(httpResponse.statusCode) {
            return output.data
        }

        let errorMessage = extractErrorMessage(from: output.data)
        throw ChatError.serverError("Request failed (\(httpResponse.statusCode)): \(errorMessage)")
    }

    private func extractErrorMessage(from data: Data) -> String {
        if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
            return apiError.error
        }

        if let text = String(data: data, encoding: .utf8), !text.isEmpty {
            return text
        }

        return "Unexpected server error"
    }

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
            .tryMap { [weak self] response in
                guard let self else { throw ChatError.serverError("Service unavailable") }
                let data = try self.validatedData(from: response, successCodes: [200])
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(Chat.self, from: data)
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
            .tryMap { [weak self] response in
                guard let self else { throw ChatError.serverError("Service unavailable") }
                let data = try self.validatedData(from: response, successCodes: [200])
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode([Chat].self, from: data)
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
            .tryMap { [weak self] response in
                guard let self else { throw ChatError.serverError("Service unavailable") }
                let data = try self.validatedData(from: response, successCodes: [200])
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode([Message].self, from: data)
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
            .tryMap { [weak self] response in
                guard let self else { throw ChatError.serverError("Service unavailable") }
                let data = try self.validatedData(from: response, successCodes: [201])
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(Message.self, from: data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Resolve Chat (seller only)

    func resolveChat(chatId: String) -> AnyPublisher<Chat, Error> {
        guard !chatId.isEmpty else {
            return Fail(error: ChatError.invalidParameters).eraseToAnyPublisher()
        }

        let urlString = "\(baseURL)/resolveChat"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = TokenManager.get() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let requestBody: [String: Any] = ["chatId": chatId]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            return Fail(error: ChatError.invalidParameters).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { [weak self] response in
                guard let self else { throw ChatError.serverError("Service unavailable") }
                let data = try self.validatedData(from: response, successCodes: [200])
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(Chat.self, from: data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

