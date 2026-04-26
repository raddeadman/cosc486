import SwiftUI
import MapKit
import CoreLocation

/// Map pin + address search for listing location, with live preview.
struct ProductLocationPickerView: View {
    @ObservedObject var viewModel: AddProductViewModel
    @State private var mapPosition: MapCameraPosition
    @State private var showMapPinSheet = false

    init(viewModel: AddProductViewModel) {
        self.viewModel = viewModel
        let center = CLLocationCoordinate2D(
            latitude: Constants.defaultMapLatitude,
            longitude: Constants.defaultMapLongitude
        )
        _mapPosition = State(
            initialValue: .region(
                MKCoordinateRegion(
                    center: center,
                    span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                )
            )
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Street, city, or place name", text: $viewModel.addressQuery)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            HStack(spacing: 12) {
                Button {
                    Task { await viewModel.lookupAddress() }
                } label: {
                    Label("Find on map", systemImage: "magnifyingglass")
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.addressQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isGeocoding)

                if viewModel.isGeocoding {
                    ProgressView()
                }
            }

            Button {
                showMapPinSheet = true
            } label: {
                Label("Drop pin on map", systemImage: "map")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Text("Opens a full-screen map. Place a pin, then tap Use this location. You can also search for an address above.")
                .font(.caption)
                .foregroundStyle(.secondary)

            previewMapBlock
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .bottomTrailing) {
                    if viewModel.pinCoordinate != nil {
                        openInAppleMapsButton
                            .padding(8)
                    }
                }

            TextField("Display name (editable)", text: $viewModel.locationName)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            if let message = viewModel.locationLookupMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(isErrorMessage(message) ? Color.red : Color.secondary)
            }
        }
        .onAppear { syncCameraFromViewModel(animated: false) }
        .onChange(of: viewModel.latitude) { _, _ in syncCameraFromViewModel(animated: true) }
        .onChange(of: viewModel.longitude) { _, _ in syncCameraFromViewModel(animated: true) }
        .sheet(isPresented: $showMapPinSheet) {
            MapPinPickerSheet(initialCoordinate: viewModel.pinCoordinate) { coordinate in
                Task { await viewModel.setPinFromMap(coordinate: coordinate) }
            }
        }
    }

    /// Read-only preview of the chosen coordinates (pin is set from the sheet or address search).
    private var previewMapBlock: some View {
        Map(position: $mapPosition) {
            if let coordinate = viewModel.pinCoordinate {
                Annotation("Pickup", coordinate: coordinate) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title)
                        .foregroundStyle(.red)
                        .shadow(radius: 2)
                }
            }
        }
        .mapStyle(.standard)
        .allowsHitTesting(false)
    }

    private var openInAppleMapsButton: some View {
        Button {
            guard let coordinate = viewModel.pinCoordinate else { return }
            let placemark = MKPlacemark(coordinate: coordinate)
            let item = MKMapItem(placemark: placemark)
            item.name = viewModel.locationName.isEmpty ? "Product location" : viewModel.locationName
            item.openInMaps()
        } label: {
            Label("Apple Maps", systemImage: "arrow.up.right.square")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func isErrorMessage(_ message: String) -> Bool {
        let lower = message.lowercased()
        return lower.contains("couldn") || lower.contains("no matching") || lower.contains("error")
    }

    private func syncCameraFromViewModel(animated: Bool) {
        guard let coordinate = viewModel.pinCoordinate else { return }
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
        if animated {
            withAnimation(.easeInOut(duration: 0.35)) {
                mapPosition = .region(region)
            }
        } else {
            mapPosition = .region(region)
        }
    }
}
