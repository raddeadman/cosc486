import Foundation
import CoreLocation

final class LocationService {
    func distance(from userLocation: CLLocation, to product: Product) -> CLLocationDistance {
        let productLocation = CLLocation(latitude: product.latitude, longitude: product.longitude)
        return userLocation.distance(from: productLocation)
    }
}
