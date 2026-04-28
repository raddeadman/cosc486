import Foundation
import CoreLocation

struct Product: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var description: String
    var price: Double
    var category: String
    var imageUrls: [String]
    var sellerId: String
    var sellerName: String
    var locationName: String
    var latitude: Double
    var longitude: Double
    var rating: Double
    var createdAt: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

