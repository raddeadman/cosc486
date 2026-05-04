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
    /// Average star rating from product-specific reviews (1–5 scale).
    let reviewAverage: Double
    let reviewCount: Int
    let isAvailable: Bool
    let createdAt: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(
        id: String,
        title: String,
        description: String,
        price: Double,
        category: String,
        imageUrls: [String],
        sellerId: String,
        sellerName: String,
        locationName: String,
        latitude: Double,
        longitude: Double,
        rating: Double,
        reviewAverage: Double = 0,
        reviewCount: Int = 0,
        isAvailable: Bool,
        createdAt: Date
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.price = price
        self.category = category
        self.imageUrls = imageUrls
        self.sellerId = sellerId
        self.sellerName = sellerName
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.rating = rating
        self.reviewAverage = reviewAverage
        self.reviewCount = reviewCount
        self.isAvailable = isAvailable
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, title, description, price, category, imageUrls, sellerId, sellerName, locationName, latitude, longitude, rating, reviewAverage, reviewCount, isAvailable, createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        let priceString = (try? container.decodeIfPresent(String.self, forKey: .price)) ?? nil
        price = (try? container.decode(Double.self, forKey: .price)) ?? priceString.flatMap { Double($0) } ?? 0.0
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
        imageUrls = try container.decodeIfPresent([String].self, forKey: .imageUrls) ?? []
        sellerId = try container.decodeIfPresent(String.self, forKey: .sellerId) ?? ""
        sellerName = try container.decodeIfPresent(String.self, forKey: .sellerName) ?? ""
        locationName = try container.decodeIfPresent(String.self, forKey: .locationName) ?? ""
        let latitudeString = (try? container.decodeIfPresent(String.self, forKey: .latitude)) ?? nil
        latitude = (try? container.decode(Double.self, forKey: .latitude)) ?? latitudeString.flatMap { Double($0) } ?? 0.0
        let longitudeString = (try? container.decodeIfPresent(String.self, forKey: .longitude)) ?? nil
        longitude = (try? container.decode(Double.self, forKey: .longitude)) ?? longitudeString.flatMap { Double($0) } ?? 0.0
        let ratingString = (try? container.decodeIfPresent(String.self, forKey: .rating)) ?? nil
        rating = (try? container.decode(Double.self, forKey: .rating)) ?? ratingString.flatMap { Double($0) } ?? 0.0
        isAvailable = try container.decodeIfPresent(Bool.self, forKey: .isAvailable) ?? false
        let reviewAvgStr = (try? container.decodeIfPresent(String.self, forKey: .reviewAverage)) ?? nil
        reviewAverage = (try? container.decode(Double.self, forKey: .reviewAverage)) ?? reviewAvgStr.flatMap { Double($0) } ?? 0.0
        let reviewCountStr = (try? container.decodeIfPresent(String.self, forKey: .reviewCount)) ?? nil
        reviewCount = (try? container.decode(Int.self, forKey: .reviewCount)) ?? reviewCountStr.flatMap { Int($0) } ?? 0

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
