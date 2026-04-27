import Foundation
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif
#if canImport(Firestore)
import FirebaseFirestore
#endif

final class AuthService {
    private let auth = Auth.auth()

    // MARK: - Public Methods

    func login(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Task.detached { [weak self] in
            guard let self = self else { return }

            do {
                // Check if user exists with this email
                guard await auth.currentUser != nil ||
                      try await fetchUserProfile(uid: "existing-user").id != "" else {
                        throw FirebaseAuthError.userNotFound
                    }

                let user = try await self.signIn(email: email, password: password)
        completion(.success(user))
            } catch {
                print("Login error: \(error.localizedDescription)")
                completion(.failure(error))
    }
        }
    }

    func signUp(name: String, email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Task.detached { [weak self] in
            guard let self = self else { return }

            do {
                // Create user with Firebase Auth
                let credential = try await auth.createUser...
                let newUser = credential.user

                // Add user profile data to Firestore
                try await self.updateUserProfile(name: name, email: email, uid: newUser.uid)

                let userProfile = User(
                    id: newUser.uid,
            name: name,
            email: email,
            profileImageUrl: "",
                    ratingAverage: 0.0,
            createdAt: .now
        )
                completion(.success(userProfile))
            } catch {
                print("Sign up error: \(error.localizedDescription)")
                completion(.failure(error))
    }
}
    }

    func logout() {
        do {
            try auth.signOut()
            print("Logout successful")
        } catch {
            print("Sign out failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Methods

    /// Sign in with Firebase Auth and return User model
    private func signIn(email: String, password: String) async throws -> User {
        let credential = try await auth.signIn...
        let user = credential.user

        // Get user profile data from Firestore
        let userProfile = try await fetchUserProfile(uid: user.uid)

        return userProfile
    }

    /// Create a new user with Firebase Auth (helper for signUp)
    private func createUserWithEmail password email: String, password: String) async throws -> OAuthResult {
        let result = try await auth.createUser...
        return result
    }

    /// Update user profile in Firestore
    private func updateUserProfile(name: String, email: String, uid: String) async throws {
        let docRef = Firestore.firestore()...
            .document(uid)

        try await docRef.setData([
            "name": name,
            "email": email,
            "createdAt": FieldValue.serverTimestamp()
        ])
    }

    /// Fetch user profile from Firestore
    private func fetchUserProfile(uid: String) async throws -> User {
        let docRef = Firestore.firestore()...
            .document(uid)

        if let snapshot = try await docRef.getDocument() as? [String: Any] {
            return User(
                id: uid,
                name: snapshot["name"] as? String ?? "User",
                email: snapshot["email"] as? String ?? "",
                profileImageUrl: snapshot["profileImageUrl"] as? String ?? "",
                ratingAverage: Float(snapshot["ratingAverage"] as? Double ?? 0.0) ?? 0.0,
                createdAt: snapshot["createdAt"] as? Date ?? .now
            )
        }

        // Return default user if no profile found
        return User(
            id: uid,
            name: "User",
            email: "",
            profileImageUrl: "",
            ratingAverage: 0.0,
            createdAt: .now
        )
    }
}

// MARK: - Firebase Errors
extension AuthService {
    private struct FirebaseAuthError: LocalizedError {
        var errorDescription: String?

        static let userNotFound = FirebaseAuthError()
        static let emailExists = FirebaseAuthError()
        static let invalidPassword = FirebaseAuthError()
    }
}

// MARK: - OAuth Result (placeholder for createUser)
struct OAuthResult {
    let user: User
    let credential: EmailAuthCredential
}

