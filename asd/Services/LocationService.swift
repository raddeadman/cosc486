import Foundation
import CoreLocation

enum LocationLookupError: LocalizedError {
    case noResults

    var errorDescription: String? {
        switch self {
        case .noResults:
            return "No matching location was found."
        }
    }
}

final class LocationService {
    private let geocoder = CLGeocoder()

    func distance(from userLocation: CLLocation, to product: Product) -> CLLocationDistance {
        let productLocation = CLLocation(latitude: product.latitude, longitude: product.longitude)
        return userLocation.distance(from: productLocation)
    }

    /// Forward geocode a free-form address string.
    func geocodeAddressString(_ address: String) async throws -> (coordinate: CLLocationCoordinate2D, label: String) {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw LocationLookupError.noResults }

        geocoder.cancelGeocode()
        let placemarks = try await geocodeAddressStringAsync(trimmed)
        guard let placemark = placemarks.first, let location = placemark.location else {
            throw LocationLookupError.noResults
        }
        let label = Self.displayLabel(from: placemark, fallback: trimmed)
        return (location.coordinate, label)
    }

    /// Reverse geocode coordinates into a human-readable place name.
    func reverseGeocode(latitude: Double, longitude: Double) async throws -> String {
        geocoder.cancelGeocode()
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let placemarks = try await reverseGeocodeLocationAsync(location)
        guard let placemark = placemarks.first else { throw LocationLookupError.noResults }
        return Self.displayLabel(from: placemark, fallback: "")
    }

    private func geocodeAddressStringAsync(_ address: String) async throws -> [CLPlacemark] {
        try await withCheckedThrowingContinuation { continuation in
            geocoder.geocodeAddressString(address) { placemarks, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: placemarks ?? [])
            }
        }
    }

    private func reverseGeocodeLocationAsync(_ location: CLLocation) async throws -> [CLPlacemark] {
        try await withCheckedThrowingContinuation { continuation in
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: placemarks ?? [])
            }
        }
    }

    private static func displayLabel(from placemark: CLPlacemark, fallback: String) -> String {
        let parts = [
            placemark.name,
            placemark.thoroughfare,
            placemark.subLocality,
            placemark.locality,
            placemark.administrativeArea,
            placemark.country
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }

        var seen = Set<String>()
        let unique = parts.filter { seen.insert($0).inserted }
        let joined = unique.joined(separator: ", ")
        if joined.isEmpty { return fallback }
        return joined
    }
}
