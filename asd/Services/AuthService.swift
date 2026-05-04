import Foundation
import Combine

// MARK: - Auth Service
// Handles all authentication-related operations with the backend API

enum AuthError: Error, LocalizedError {
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

final class AuthService {
    private let baseURL = "https://us-central1-openmarketmobile.cloudfunctions.net"

    private struct APIErrorResponse: Decodable {
        let error: String
    }

    private func validatedData(
        from output: URLSession.DataTaskPublisher.Output,
        successCodes: Set<Int>
    ) throws -> Data {
        guard let httpResponse = output.response as? HTTPURLResponse else {
            throw AuthError.serverError("Invalid server response")
        }
        if successCodes.contains(httpResponse.statusCode) {
            return output.data
        }
        let message: String
        if let api = try? JSONDecoder().decode(APIErrorResponse.self, from: output.data) {
            message = api.error
        } else if let text = String(data: output.data, encoding: .utf8), !text.isEmpty {
            message = text
        } else {
            message = "Unexpected server error"
        }
        throw AuthError.serverError("Request failed (\(httpResponse.statusCode)): \(message)")
    }

    // MARK: - Login

    func login(email: String, password: String) -> AnyPublisher<User, Error> {
        guard !email.isEmpty, !password.isEmpty else {
            return Fail(error: AuthError.invalidParameters).eraseToAnyPublisher()
        }

        let urlString = "\(baseURL)/login"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "email": email,
            "password": password
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            return Fail(error: AuthError.invalidParameters).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { response in
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let loginResponse = try decoder.decode(LoginResponse.self, from: response.data)
                TokenManager.save(token: loginResponse.token)
                return loginResponse.user
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Sign Up

    func signUp(name: String, email: String, password: String) -> AnyPublisher<User, Error> {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            return Fail(error: AuthError.invalidParameters).eraseToAnyPublisher()
        }

        let urlString = "\(baseURL)/signUp"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "name": name,
            "email": email,
            "password": password
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            return Fail(error: AuthError.invalidParameters).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { response in
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let loginResponse = try decoder.decode(LoginResponse.self, from: response.data)
                TokenManager.save(token: loginResponse.token)
                return loginResponse.user
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Logout

    func logout() -> AnyPublisher<Bool, Error> {
        let urlString = "\(baseURL)/logout"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "POST"

        if let token = TokenManager.get() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { _ in
                TokenManager.clear()
                return true
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Fetch User Profile

    func fetchUserProfile(uid: String) -> AnyPublisher<User, Error> {
        guard !uid.isEmpty else {
            return Fail(error: AuthError.invalidParameters).eraseToAnyPublisher()
        }

        var components = URLComponents(string: "\(baseURL)/fetchUserProfile")!
        components.queryItems = [URLQueryItem(name: "uid", value: uid)]
        guard let url = components.url else {
            return Fail(error: AuthError.invalidParameters).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let token = TokenManager.get() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { [weak self] output in
                guard let self else { throw AuthError.serverError("Service unavailable") }
                let data = try self.validatedData(from: output, successCodes: [200])
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(User.self, from: data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Update User Profile

    /// Email is not updated via this API. Pass `nil` for fields you are not changing.
    func updateUserProfile(name: String?, profileImageUrl: String?, uid: String) -> AnyPublisher<User, Error> {
        guard !uid.isEmpty else {
            return Fail(error: AuthError.invalidParameters).eraseToAnyPublisher()
        }

        let hasName = name != nil
        let hasUrl = profileImageUrl != nil && !(profileImageUrl ?? "").isEmpty
        guard hasName || hasUrl else {
            return Fail(error: AuthError.invalidParameters).eraseToAnyPublisher()
        }

        var components = URLComponents(string: "\(baseURL)/updateUserProfile")!
        components.queryItems = [URLQueryItem(name: "uid", value: uid)]
        guard let url = components.url else {
            return Fail(error: AuthError.invalidParameters).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = TokenManager.get() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var requestBody: [String: Any] = [:]
        if let name {
            requestBody["name"] = name
        }
        if let profileImageUrl, !profileImageUrl.isEmpty {
            requestBody["profileImageUrl"] = profileImageUrl
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            return Fail(error: AuthError.invalidParameters).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { [weak self] output in
                guard let self else { throw AuthError.serverError("Service unavailable") }
                let data = try self.validatedData(from: output, successCodes: [200])
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(User.self, from: data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// MARK: - Response Models

struct LoginResponse: Codable {
    let token: String
    let user: User
}
