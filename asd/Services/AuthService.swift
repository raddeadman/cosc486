import Foundation
import FirebaseAuth
import FirebaseFirestore

final class AuthService {
    private let auth = Auth.auth()

    func login(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Task.detached { [weak self] in
            guard let self = self else { return }

            do {
                let result = try await auth.signIn(withEmail: email, password: password)
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
                // Verify password strength first
                guard password.count >= 6 else {
                    throw NSError(domain: "AuthService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Password must be at least 6 characters"])
                }

                print("Starting sign up for: \(email)")

                // Create user with Firebase Auth
                let newUser = try await auth.createUser(withEmail: email, password: password)
                print("User created successfully with UID: \(newUser.user.uid)")

                // Add user profile data to Firestore
                try await self.updateUserProfile(name: name, email: email, uid: newUser.user.uid)
                print("User profile saved to Firestore")

                let userProfile = User(
                    id: newUser.user.uid,
                    name: name,
                    email: email,
                    profileImageUrl: "",
                    ratingAverage: 0.0,
                    createdAt: .now
                )
                completion(.success(userProfile))
            } catch FirebaseAuthError.code(.emailAlreadyInUse) {
                print("Sign up error: Email already exists")
                // Try to sign in instead
                do {
                    let signedInUser = try await auth.signIn(withEmail: email, password: password)
                    let userProfile = try await self.fetchUserProfile(uid: signedInUser.user.uid)
                    completion(.success(userProfile))
        } catch {
                    completion(.failure(error))
        }
            } catch FirebaseAuthError.code(.weakPassword) {
                print("Sign up error: Password is too weak")
                completion(.failure(NSError(domain: "AuthService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Password must be at least 6 characters"])))
            } catch {
                print("Sign up error: \(error.localizedDescription)")

                // Additional debugging - check if it's a network issue
                if let firebaseError = error as? FirebaseAuthError {
                    print("Firebase error code: \(firebaseError.code)")
                    print("Firebase error message: \(firebaseError.localizedDescription)")
    }

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
    private func updateUserProfile(name: String, email: String, uid: String) async throws {
        let docRef = Firestore.firestore().collection("users").document(uid)

        try await docRef.setData([
            "name": name,
            "email": email,
            "createdAt": FieldValue.serverTimestamp()
        ])
    }

    func fetchUserProfile(uid: String) async throws -> User {
        let docRef = Firestore.firestore().collection("users").document(uid)

        let snapshot = try await docRef.getDocument()
        if let data = snapshot.data() {
            return User(
                id: uid,
                name: data["name"] as? String ?? "User",
                email: data["email"] as? String ?? "",
                profileImageUrl: data["profileImageUrl"] as? String ?? "",
                ratingAverage: data["ratingAverage"] as? Double ?? 0.0,
                createdAt: data["createdAt"] as? Date ?? .now
            )
        }

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

extension AuthService {
    private struct FirebaseAuthError: LocalizedError {
        var errorDescription: String?

        static let code: (AuthErrorCode.Type) -> FirebaseAuthError = { _ in
            return FirebaseAuthError()
    }

        static let userNotFound = FirebaseAuthError()
        static let emailExists = FirebaseAuthError()
        static let invalidPassword = FirebaseAuthError()
}
}


