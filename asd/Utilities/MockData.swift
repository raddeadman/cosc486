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
            isAvailable: true,
            createdAt: .now
        ),
        Product(
            id: "p2",
            title: "PlayStation 5 Console",
            description: "Lightly used PS5 with one controller and original box.",
            price: 210,
            category: "Electronics",
            imageUrls: ["placeholder"],
            sellerId: "u1",
            sellerName: "Sara Ali",
            locationName: "Riffa",
            latitude: 26.1290,
            longitude: 50.5550,
            rating: 4.8,
            isAvailable: true,
            createdAt: .now.addingTimeInterval(-86_400)
        ),
        Product(
            id: "p3",
            title: "Wooden Dining Table Set",
            description: "Six-seater dining table in great condition.",
            price: 180,
            category: "Home",
            imageUrls: ["placeholder"],
            sellerId: "u1",
            sellerName: "Sara Ali",
            locationName: "Isa Town",
            latitude: 26.1732,
            longitude: 50.5470,
            rating: 4.4,
            isAvailable: false,
            createdAt: .now.addingTimeInterval(-2 * 86_400)
        ),
        Product(
            id: "p4",
            title: "Nike Air Max 270",
            description: "Size 42, worn a few times, clean and comfortable.",
            price: 42,
            category: "Fashion",
            imageUrls: ["placeholder"],
            sellerId: "u1",
            sellerName: "Sara Ali",
            locationName: "Muharraq",
            latitude: 26.2570,
            longitude: 50.6119,
            rating: 4.5,
            isAvailable: true,
            createdAt: .now.addingTimeInterval(-3 * 86_400)
        ),
        Product(
            id: "p5",
            title: "Canon EOS M50 Camera",
            description: "Mirrorless camera with kit lens and charger.",
            price: 320,
            category: "Electronics",
            imageUrls: ["placeholder"],
            sellerId: "u1",
            sellerName: "Sara Ali",
            locationName: "Saar",
            latitude: 26.2076,
            longitude: 50.4882,
            rating: 4.9,
            isAvailable: true,
            createdAt: .now.addingTimeInterval(-4 * 86_400)
        ),
        Product(
            id: "p6",
            title: "Road Bike 700C",
            description: "Aluminum frame road bike, recently serviced.",
            price: 155,
            category: "Sports",
            imageUrls: ["placeholder"],
            sellerId: "u1",
            sellerName: "Sara Ali",
            locationName: "Hamad Town",
            latitude: 26.1153,
            longitude: 50.5060,
            rating: 4.3,
            isAvailable: false,
            createdAt: .now.addingTimeInterval(-5 * 86_400)
        ),
        Product(
            id: "p7",
            title: "MacBook Air M1",
            description: "13-inch, 8GB RAM, 256GB SSD, battery health excellent.",
            price: 490,
            category: "Electronics",
            imageUrls: ["placeholder"],
            sellerId: "u1",
            sellerName: "Sara Ali",
            locationName: "Budaiya",
            latitude: 26.2193,
            longitude: 50.4525,
            rating: 4.7,
            isAvailable: true,
            createdAt: .now.addingTimeInterval(-6 * 86_400)
        ),
        Product(
            id: "p8",
            title: "Baby Stroller",
            description: "Foldable stroller with storage basket, very clean.",
            price: 35,
            category: "Kids",
            imageUrls: ["placeholder"],
            sellerId: "u1",
            sellerName: "Sara Ali",
            locationName: "Juffair",
            latitude: 26.2130,
            longitude: 50.6070,
            rating: 4.2,
            isAvailable: true,
            createdAt: .now.addingTimeInterval(-7 * 86_400)
        )
    ]
}
