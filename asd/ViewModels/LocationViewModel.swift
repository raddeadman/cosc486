import Foundation
import Combine
import CoreLocation

final class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var nearbyProducts: [Product] = []
    @Published var userLocation: CLLocation?

    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        locationManager.delegate = self
    }

    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func loadNearbyProducts() {
        nearbyProducts = MockData.products
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
    }
}

