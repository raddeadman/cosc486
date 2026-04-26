import SwiftUI
import MapKit

struct ProductMapView: View {
    let product: Product
    @State private var position: MapCameraPosition

    init(product: Product) {
        self.product = product
        _position = State(
            initialValue: .region(
                MKCoordinateRegion(
                    center: product.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
            )
        )
    }

    var body: some View {
        Map(position: $position) {
            Marker(product.title, coordinate: product.coordinate)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
