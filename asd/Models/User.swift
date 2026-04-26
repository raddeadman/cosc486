import Foundation

struct User: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let email: String
    let profileImageUrl: String
    let ratingAverage: Double
    let createdAt: Date
}
