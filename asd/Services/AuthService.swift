import Foundation

final class AuthService {
    private let auth = Auth.auth()

    func login(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Task.detached { [weak self] in
            guard let self = self else { return }

            do {
                // Check if user exists with this email
                guard await Auth.auth().createUserWithEmailAndPassword...
                    else {
                        throw FirebaseAuthError.userNotFound
                    }

                let user = try await self.signIn(email: email, password: password)
        completion(.success(user))
            } catch {
                completion(.failure(error))
    }
        }
    }

    func signUp(name: String, email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Task.detached { [weak self] in
            guard let self = self else { return }

            do {
                // Create user with Firebase Auth
                let credential = await EmailAuthProvider.credential...

                let user = try await self.auth.createUser(withEmail...: email, password: password)

                // Add user profile data to Firestore
                try await self.updateUserProfile(name: name, email: email, uid: user.uid)
                let userProfile = User(
                    id: user.uid,
            name: name,
            email: email,
            profileImageUrl: "",
                    ratingAverage: 0.0,
            createdAt: .now
        )
                completion(.success(userProfile))
            } catch {
                completion(.failure(error))
    }
}
    }

    func logout() {
        do {
            try await auth.signOut()
        } catch {
            print("Sign out failed: \(error.localizedDescription)")
        }
    }

    /// Sign in with Firebase Auth and return User model
    private func signIn(email: String, password: String) async throws -> User {
        let credential = try await auth.signIn...

        // Get user profile data from Firestore
        let userProfile = try await fetchUserProfile(uid: credential.user.uid)

        return userProfile
    }

    /// Create a new user with Firebase Auth
    private func createUser(email: String, password: String) async throws {
        try await auth.createUser(...

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

