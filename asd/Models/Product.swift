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

    enum CodingKeys: String, CodingKey {
        case id, title, description, price, category, imageUrls, sellerId, sellerName, locationName, latitude, longitude, rating, isAvailable, createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        price = (try? container.decode(Double.self, forKey: .price)) ?? Double(try container.decodeIfPresent(String.self, forKey: .price) ?? "") ?? 0.0
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
        imageUrls = try container.decodeIfPresent([String].self, forKey: .imageUrls) ?? []
        sellerId = try container.decodeIfPresent(String.self, forKey: .sellerId) ?? ""
        sellerName = try container.decodeIfPresent(String.self, forKey: .sellerName) ?? ""
        locationName = try container.decodeIfPresent(String.self, forKey: .locationName) ?? ""
        latitude = (try? container.decode(Double.self, forKey: .latitude)) ?? Double(try container.decodeIfPresent(String.self, forKey: .latitude) ?? "") ?? 0.0
        longitude = (try? container.decode(Double.self, forKey: .longitude)) ?? Double(try container.decodeIfPresent(String.self, forKey: .longitude) ?? "") ?? 0.0
        rating = (try? container.decode(Double.self, forKey: .rating)) ?? Double(try container.decodeIfPresent(String.self, forKey: .rating) ?? "") ?? 0.0
        isAvailable = try container.decodeIfPresent(Bool.self, forKey: .isAvailable) ?? false

        if let date = try? container.decode(Date.self, forKey: .createdAt) {
            createdAt = date
        } else if let stringValue = try? container.decode(String.self, forKey: .createdAt),
                  let parsedDate = ISO8601DateFormatter().date(from: stringValue) {
            createdAt = parsedDate
        } else {
            createdAt = Date()
        }
    }
}
