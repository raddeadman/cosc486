import Foundation

extension Date {
    var shortDateText: String {
        formatted(date: .abbreviated, time: .shortened)
    }
}

extension Double {
    var formattedPrice: String {
        formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }

    var formattedDistance: String {
        if self < 1000 { return "\(Int(self)) m" }
        return String(format: "%.1f km", self / 1000)
    }
}
