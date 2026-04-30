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
    private let baseURL = "https://api.example.com/v1"

    // MARK: - Login

    func login(email: String, password: String) -> AnyPublisher<User, Error> {
        guard !email.isEmpty, !password.isEmpty else {
            return Fail(error: AuthError.invalidParameters).eraseToAnyPublisher()
        }

        let urlString = "\(baseURL)/auth/login"
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
            .tryMap(\.response)
            .decode(type: LoginResponse.self, decoder: JSONDecoder())
            .map(\.user)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Sign Up

    func signUp(name: String, email: String, password: String) -> AnyPublisher<User, Error> {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            return Fail(error: AuthError.invalidParameters).eraseToAnyPublisher()
        }

        let urlString = "\(baseURL)/auth/register"
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
            .tryMap(\.response)
            .decode(type: LoginResponse.self, decoder: JSONDecoder())
            .map(\.user)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Logout

    func logout(token: String) -> AnyPublisher<Bool, Error> {
        let urlString = "\(baseURL)/auth/logout"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { _ in true }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Fetch User Profile

    func fetchUserProfile(uid: String) -> AnyPublisher<User, Error> {
        let urlString = "\(baseURL)/users/\(uid)"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "GET"

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap(\.response)
            .decode(type: User.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Update User Profile

    func updateUserProfile(name: String, email: String, uid: String) -> AnyPublisher<User, Error> {
        guard !name.isEmpty, !email.isEmpty else {
            return Fail(error: AuthError.invalidParameters).eraseToAnyPublisher()
        }

        let urlString = "\(baseURL)/users/\(uid)"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "name": name,
            "email": email
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            return Fail(error: AuthError.invalidParameters).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap(\.response)
            .decode(type: User.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// MARK: - Response Models

struct LoginResponse: Codable {
    let token: String
    let user: User
}

extension Data {
    fileprivate func response() throws -> (data: Data) {
        guard let httpResponse = HTTPURLResponse(
            statusCode: 200,
            headers: [:],
            url: URL(string: "https://api.example.com/v1")!
        ) else {
            throw URLError(.badServerResponse)
        }
        return (self, httpResponse)
    }
}