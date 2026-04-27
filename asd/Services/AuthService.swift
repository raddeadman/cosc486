import Foundation
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif
#if canImport(Firestore)
import FirebaseFirestore
#endif

final class AuthService {
    private let auth = Auth.auth()

    func login(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Task.detached { [weak self] in
            guard let self = self else { return }

            do {
                // Sign in with Firebase Auth
                let result = try await auth.signIn(withEmail: email, password: password)

        // Get user profile data from Firestore
                let userProfile = try await self.fetchUserProfile(uid: result.user.uid)
                completion(.success(userProfile))
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
                let newUser = try await auth.createUser(withEmail: email, password: password)

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

    /// Update user profile in Firestore
    private func updateUserProfile(name: String, email: String, uid: String) async throws {
        let docRef = Firestore.firestore().collection("users").document(uid)

        try await docRef.setData([
            "name": name,
            "email": email,
            "createdAt": FieldValue.serverTimestamp()
        ])
    }

    /// Fetch user profile from Firestore
    func fetchUserProfile(uid: String) async throws -> User {
        let docRef = Firestore.firestore().collection("users").document(uid)

        let snapshot = try await docRef.getDocument()
        if let data = snapshot.data() {
            return User(
                id: uid,
                name: data["name"] as? String ?? "User",
                email: data["email"] as? String ?? "",
                profileImageUrl: data["profileImageUrl"] as? String ?? "",
                ratingAverage: data["ratingAverage"] as? Float ?? 0.0,
                createdAt: data["createdAt"] as? Date ?? .now
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

