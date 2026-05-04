import Foundation
import Combine
import CoreLocation

final class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var nearbyProducts: [Product] = []
    @Published var userLocation: CLLocation?

    private let locationManager = CLLocationManager()
    private let productService = ProductService()
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
        guard let location = userLocation else {
            nearbyProducts = []
            return
        }

        productService.fetchProducts(lat: location.coordinate.latitude,
                                     lng: location.coordinate.longitude,
                                     radiusKm: 50)
            .sink { completion in
                // Handle completion if necessary
            } receiveValue: { products in
                self.nearbyProducts = products
            }
            .store(in: &cancellables)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
    }
}

