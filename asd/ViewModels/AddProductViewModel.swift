import Foundation
import Combine
import CoreLocation

@MainActor
final class AddProductViewModel: ObservableObject {
    @Published var selectedImages: [Data] = []
    @Published var title = ""
    @Published var description = ""
    @Published var category = Constants.categories.first ?? "General"
    @Published var priceText = ""
    /// Editable label shown to buyers (filled from geocode / reverse geocode, user can override).
    @Published var locationName = ""
    /// Free-form address search (separate from display name).
    @Published var addressQuery = ""
    @Published var latitude: Double?
    @Published var longitude: Double?
    @Published var isSubmitting = false
    @Published var isGeocoding = false
    @Published var locationLookupMessage: String?
    @Published var submissionMessage: String?
    @Published var submissionIsError = false

    private let productService = ProductService()
    private let locationService = LocationService()
    private var cancellables = Set<AnyCancellable>()

    var pinCoordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    func setPinFromMap(coordinate: CLLocationCoordinate2D) async {
        locationLookupMessage = nil
        latitude = coordinate.latitude
        longitude = coordinate.longitude
        await refreshReverseGeocodeLabel()
    }

    func lookupAddress() async {
        let query = addressQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        locationLookupMessage = nil
        isGeocoding = true
        defer { isGeocoding = false }
        do {
            let result = try await locationService.geocodeAddressString(query)
            latitude = result.coordinate.latitude
            longitude = result.coordinate.longitude
            locationName = result.label
            locationLookupMessage = "Found: \(result.label)"
        } catch {
            locationLookupMessage = error.localizedDescription
        }
    }

    private func refreshReverseGeocodeLabel() async {
        guard let lat = latitude, let lon = longitude else { return }
        isGeocoding = true
        defer { isGeocoding = false }
        do {
            let label = try await locationService.reverseGeocode(latitude: lat, longitude: lon)
            if !label.isEmpty {
                locationName = label
            }
            locationLookupMessage = "Pin updated."
        } catch {
            locationLookupMessage = "Couldn’t resolve address for pin. You can still type a display name."
        }
    }

    func submitProduct() {
        guard validate() else {
            submissionIsError = true
            submissionMessage = "Please fill all fields and choose a location."
            return
        }
        guard let lat = latitude, let lon = longitude else {
            submissionIsError = true
            submissionMessage = "Please select a valid location."
            return
        }

        submissionMessage = nil
        submissionIsError = false
        isSubmitting = true

        productService.submitPlaceholderProduct(
            title: title,
            description: description,
            category: category,
            priceText: priceText,
            locationName: locationName.trimmingCharacters(in: .whitespacesAndNewlines),
            latitude: lat,
            longitude: lon
        )
        .sink { [weak self] completion in
            guard let self = self else { return }
            self.isSubmitting = false
            switch completion {
            case .finished:
                self.submissionIsError = false
                self.submissionMessage = "Product submitted successfully."
            case .failure(let error):
                self.submissionIsError = true
                self.submissionMessage = error.localizedDescription
            }
        } receiveValue: { _ in }
        .store(in: &cancellables)
    }

    func validate() -> Bool {
        guard let lat = latitude, let lon = longitude else { return false }
        let hasCoords = abs(lat) <= 90 && abs(lon) <= 180
        let hasLabel = !locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            Double(priceText) != nil &&
            hasCoords &&
            hasLabel
    }
}

