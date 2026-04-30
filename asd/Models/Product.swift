import Foundation
import CoreLocation

struct Product: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let description: String
    let price: Double
    let category: String
    let imageUrls: [String]
    let sellerId: String
    let sellerName: String
    let locationName: String
    let latitude: Double
    let longitude: Double
    let rating: Double
    let isAvailable: Bool
    let createdAt: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
