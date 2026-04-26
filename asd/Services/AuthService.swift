import Foundation

final class AuthService {
    func login(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        let user = User(
            id: UUID().uuidString,
            name: "Demo User",
            email: email,
            profileImageUrl: "",
            ratingAverage: 4.5,
            createdAt: .now
        )
        completion(.success(user))
    }

    func signUp(name: String, email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        let user = User(
            id: UUID().uuidString,
            name: name,
            email: email,
            profileImageUrl: "",
            ratingAverage: 0,
            createdAt: .now
        )
        completion(.success(user))
    }

    func logout() {}
}
