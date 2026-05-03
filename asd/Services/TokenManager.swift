// MARK: - Token Manager
// Centralized storage and retrieval of authentication tokens

import Foundation

final class TokenManager {
    private static let key = "auth_token"
    private static let defaults = UserDefaults.standard

    static func save(token: String) {
        defaults.set(token, forKey: key)
    }

    static func get() -> String? {
        return defaults.string(forKey: key)
    }

    static func clear() {
        defaults.removeObject(forKey: key)
    }
}
