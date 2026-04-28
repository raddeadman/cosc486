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

                // Create user with Firebase Auth only - profile will be created by Cloud Function
                let newUser = try await auth.createUser(withEmail: email, password: password)
                print("User created successfully in Firebase Auth")

                // NOTE: User profile is automatically created in Firestore by onAuthUserCreate Cloud Function
                // No need to manually write to Firestore here - this is handled server-side securely
                let userProfile = User(
                    id: newUser.user.uid,
                    name: name,
                    email: email,
                    profileImageUrl: "", // Will be set automatically by Cloud Function
                    ratingAverage: 0.0,
                    createdAt: .now
                )

                print("Waiting for Cloud Function to create user profile in Firestore...")
                completion(.success(userProfile))
            } catch {
                print("Sign up error: \(error.localizedDescription)")

                // Try to sign in instead if user already exists
                do {
                    let signedInUser = try await auth.signIn(withEmail: email, password: password)
                    let userProfile = try await self.fetchUserProfile(uid: signedInUser.user.uid)
                    completion(.success(userProfile))
                } catch {
                    print("Failed to sign in after sign up error")
                    completion(.failure(error))
                }
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
        // REMOVED: This function is no longer needed for initial user creation
        // Profile creation is now handled by onAuthUserCreate Cloud Function

        // Keep this only for profile updates (not initial creation)
        let docRef = Firestore.firestore().collection("users").document(uid)

        try await docRef.setData([
            "name": name,
            "email": email,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)
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

