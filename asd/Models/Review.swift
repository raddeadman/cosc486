import Foundation

struct Review: Identifiable, Codable, Hashable {
    let id: String
    let reviewerId: String
    let sellerId: String
    let rating: Int
    let comment: String
    let timestamp: Date
}
