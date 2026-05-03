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

        let urlString = "https://us-central1-openmarketmobile.cloudfunctions.net/login"
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
                let loginResponse = try decoder.decode(LoginResponse.self, from: response.data)
                TokenManager.save(token: loginResponse.token)  // Save token here
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

        let urlString = "https://us-central1-openmarketmobile.cloudfunctions.net/signUp"
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
                let loginResponse = try decoder.decode(LoginResponse.self, from: response.data)
                TokenManager.save(token: loginResponse.token)  // Save token here
                return loginResponse.user
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Logout

    func logout() -> AnyPublisher<Bool, Error> {
        let urlString = "https://us-central1-openmarketmobile.cloudfunctions.net/logout"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "POST"

        if let token = TokenManager.get() {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { _ in
                TokenManager.clear()  // Clear token after logout
                return true
    }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Fetch User Profile

    func fetchUserProfile(uid: String) -> AnyPublisher<User, Error> {
        let urlString = "https://us-central1-openmarketmobile.cloudfunctions.net/fetchUserProfile"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "GET"

        if let token = TokenManager.get() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { response in
                let decoder = JSONDecoder()
                return try decoder.decode(User.self, from: response.data)
    }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
}

    // MARK: - Update User Profile

    func updateUserProfile(name: String, email: String, uid: String) -> AnyPublisher<User, Error> {
        guard !name.isEmpty, !email.isEmpty else {
            return Fail(error: AuthError.invalidParameters).eraseToAnyPublisher()
        }

        let urlString = "https://us-central1-openmarketmobile.cloudfunctions.net/updateUserProfile"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = TokenManager.get() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

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
            .tryMap { response in
                let decoder = JSONDecoder()
                return try decoder.decode(User.self, from: response.data)
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