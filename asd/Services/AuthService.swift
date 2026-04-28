import Foundation
import FirebaseAuth
import FirebaseFirestore

final class AuthService {
    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    // Maximum number of retries when waiting for profile creation
    private static let maxRetries = 3
    private static let retryDelay: TimeInterval = 0.5 // 500ms between retries

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
                    throw NSError(domain: "AuthService", code: 400, userInfo: [
                        NSLocalizedDescriptionKey: "Password must be at least 6 characters"
                    ])
                }

                print("Starting sign up for: \(email)")

                // Create user with Firebase Auth
                let newUser = try await auth.createUser(withEmail: email, password: password)
                print("User created successfully in Firebase Auth (UID: \(newUser.user.uid))")

                // Wait for the Cloud Function to create the profile
                let userProfile = try await self.waitForProfileCreation(uid: newUser.user.uid)

                try await self.updateUserProfile(
                    name: name,
                    email: email,
                    uid: newUser.user.uid
                )

                completion(.success(userProfile))
            } catch {
                handleSignUpError(error, email: email, password: password, completion: completion)
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
        let docRef = db.collection("users").document(uid)

        try await docRef.setData([
            "name": name,
            "email": email,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)
    }

func fetchUserProfile(uid: String) async throws -> User {
    let docRef = db.collection("users").document(uid)

    do {
        let snapshot = try await docRef.getDocument()

        if let data = snapshot.data() {
            return User(
                id: uid,
                name: data["name"] as? String ?? "User",
                email: data["email"] as? String ?? "",
                profileImageUrl: data["profileImageUrl"] as? String ?? "",
                ratingAverage: data["ratingAverage"] as? Double ?? 0.0,
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            )
        }

        if snapshot.exists {
            return User(
                id: uid,
                name: "User",
                email: "",
                profileImageUrl: "",
                ratingAverage: 0.0,
                createdAt: Date()
            )
        }

        throw AuthError.userProfileNotFound
    } catch {
        print("Error fetching user profile: \(error.localizedDescription)")
        throw error
    }
}

    /// Waits for the Cloud Function to create a user profile in Firestore
private func waitForProfileCreation(uid: String) async throws -> User {
    var retryCount = 0

    while retryCount < AuthService.maxRetries {
        do {
            let profile = try await fetchUserProfile(uid: uid)

            if !profile.profileImageUrl.isEmpty || profile.ratingAverage > 0.0 {
                print("Profile creation completed successfully")
                return profile
            }

            retryCount += 1
            if retryCount < AuthService.maxRetries {
                try await Task.sleep(nanoseconds: UInt64(AuthService.retryDelay * 1_000_000_000))
                print("Retrying profile fetch (attempt \(retryCount)/\(AuthService.maxRetries))...")
            }
        } catch {
            if retryCount == AuthService.maxRetries - 1 {
                throw error
            }
            retryCount += 1
            try await Task.sleep(nanoseconds: UInt64(AuthService.retryDelay * 1_000_000_000))
        }
    }

    throw AuthError.profileCreationTimeout
}

private func handleSignUpError(_ error: Error, email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
    print("Sign up error: \(error.localizedDescription)")

    // Try to sign in if user already exists (common for duplicate emails)
    Task { [weak self] in
        guard let self = self else { return }

        do {
            let signedInUser = try await auth.signIn(withEmail: email, password: password)

            // Wait for profile creation (might have been created on previous attempt)
            let userProfile = try await waitForProfileCreation(uid: signedInUser.user.uid)
            completion(.success(userProfile))
        } catch {
            print("Failed to sign in after sign up error")
            completion(.failure(error))
        }
    }
}
}

// Custom auth errors for better error handling
enum AuthError: Error, LocalizedError {
    case userProfileNotFound
    case profileCreationTimeout

    var errorDescription: String? {
        switch self {
        case .userProfileNotFound:
            return "User profile not found in Firestore"
        case .profileCreationTimeout:
            return "Failed to create user profile after maximum retries"
        }
    }
}