import SwiftUI

enum Constants {
    static let primaryColor = Color.blue
    static let secondaryColor = Color.indigo

    /// Default map center (Manama) when no pin is set yet.
    static let defaultMapLatitude = 26.2235
    static let defaultMapLongitude = 50.5876

    static let categories = [
        "All",
        "Electronics",
        "Furniture",
        "Fashion",
        "Vehicles",
        "Books",
        "Other"
    ]

    enum Collections {
        static let users = "users"
        static let products = "products"
        static let chats = "chats"
        static let messages = "messages"
        static let reviews = "reviews"
        static let favorites = "favorites"
    }
}
