import SwiftUI
import MapKit
import CoreLocation

/// Full-screen map (MapKit, same data as Apple Maps) to place a pin and confirm.
/// The standalone Maps app cannot return a chosen pin to third-party apps; this sheet matches that workflow in-app.
struct MapPinPickerSheet: View {
    let initialCoordinate: CLLocationCoordinate2D?
    let onConfirm: (CLLocationCoordinate2D) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var draftCoordinate: CLLocationCoordinate2D?
    @State private var mapPosition: MapCameraPosition
    /// Center of the visible map region (updated while panning/zooming); used for crosshair placement.
    @State private var mapCenterCoordinate: CLLocationCoordinate2D

    init(initialCoordinate: CLLocationCoordinate2D?, onConfirm: @escaping (CLLocationCoordinate2D) -> Void) {
        self.initialCoordinate = initialCoordinate
        self.onConfirm = onConfirm
        let center = initialCoordinate
            ?? CLLocationCoordinate2D(latitude: Constants.defaultMapLatitude, longitude: Constants.defaultMapLongitude)
        _draftCoordinate = State(initialValue: initialCoordinate)
        _mapCenterCoordinate = State(initialValue: center)
        _mapPosition = State(
            initialValue: .region(
                MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
            )
        )
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                mapContent
                    .ignoresSafeArea(edges: .bottom)

                Text("Click or tap the map to drop a pin (small movements only), or pan under the crosshair and tap Place pin here.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .padding(.horizontal)
            }
            .navigationTitle("Pin location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Use this location") {
                        guard let coordinate = draftCoordinate else { return }
                        onConfirm(coordinate)
                        dismiss()
                    }
                    .disabled(draftCoordinate == nil)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var mapContent: some View {
        MapReader { proxy in
            ZStack {
                Map(position: $mapPosition) {
                    if let coordinate = draftCoordinate {
                        Annotation("Pickup", coordinate: coordinate) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.red)
                                .shadow(radius: 3)
                        }
                    }
                }
                .mapStyle(.standard)
                .onMapCameraChange(frequency: .continuous) { context in
                    mapCenterCoordinate = context.region.center
                }
                // `Map` eats normal tap gestures; `SpatialTapGesture` + simultaneous `DragGesture` (tiny movement = tap) both reach the map.
                .simultaneousGesture(
                    SpatialTapGesture()
                        .onEnded { event in
                            guard let coordinate = proxy.convert(event.location, from: .local) else { return }
                            applyPin(coordinate)
                        }
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            let drag = hypot(value.translation.width, value.translation.height)
                            guard drag < 18 else { return }
                            guard let coordinate = proxy.convert(value.startLocation, from: .local) else { return }
                            applyPin(coordinate)
                        }
                )

                crosshairOverlay
                    .allowsHitTesting(false)

                VStack {
                    Spacer()
                    Button {
                        applyPin(mapCenterCoordinate)
                    } label: {
                        Label("Place pin here", systemImage: "mappin.and.ellipse")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
            }
        }
    }

    private var crosshairOverlay: some View {
        ZStack {
            Rectangle()
                .fill(Color.primary.opacity(0.35))
                .frame(width: 1, height: 28)
            Rectangle()
                .fill(Color.primary.opacity(0.35))
                .frame(width: 28, height: 1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func applyPin(_ coordinate: CLLocationCoordinate2D) {
        draftCoordinate = coordinate
        centerMap(on: coordinate, animated: true)
    }

    private func centerMap(on coordinate: CLLocationCoordinate2D, animated: Bool) {
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
