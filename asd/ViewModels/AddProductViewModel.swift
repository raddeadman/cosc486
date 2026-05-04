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
    private let storageService = StorageService()
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

    private func uploadAllImages() -> AnyPublisher<[String], Error> {
        guard !selectedImages.isEmpty else {
            return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
        }

        let first = storageService.uploadImageData(file: selectedImages[0], fileName: "listing-0.jpg")
            .map { [$0.url] }
            .eraseToAnyPublisher()

        return selectedImages.dropFirst().enumerated().reduce(first) { accumulator, pair in
            let (idx, data) = pair
            let i = idx + 1
            return accumulator.flatMap { urls in
                self.storageService.uploadImageData(file: data, fileName: "listing-\(i).jpg")
                    .map { urls + [$0.url] }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
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

        uploadAllImages()
            .flatMap { [weak self] urls -> AnyPublisher<Product, Error> in
                guard let self else {
                    return Fail(error: ProductError.invalidParameters).eraseToAnyPublisher()
                }
                return self.productService.submitPlaceholderProduct(
                    title: self.title,
                    description: self.description,
                    category: self.category,
                    priceText: self.priceText,
                    locationName: self.locationName.trimmingCharacters(in: .whitespacesAndNewlines),
                    latitude: lat,
                    longitude: lon,
                    imageUrls: urls
                )
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }
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
