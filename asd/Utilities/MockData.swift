import Foundation

enum MockData {
    static let users: [User] = [
        User(
            id: "u1",
            name: "Sara Ali",
            email: "sara@example.com",
            profileImageUrl: "",
            ratingAverage: 4.7,
            createdAt: .now
        )
    ]

    static let products: [Product] = [
        Product(
            id: "p1",
            title: "iPhone 14 Pro",
            description: "Excellent condition, 256GB.",
            price: 650,
            category: "Electronics",
            imageUrls: ["placeholder"],
            sellerId: "u1",
            sellerName: "Sara Ali",
            locationName: "Manama",
            latitude: 26.2235,
            longitude: 50.5876,
            rating: 4.6,
            createdAt: .now
        )
    ]
}
