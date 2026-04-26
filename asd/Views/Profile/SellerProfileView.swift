import SwiftUI

struct SellerProfileView: View {
    let seller: User

    var body: some View {
        List {
            Text(seller.name).font(.headline)
            Text("Rating: \(seller.ratingAverage.formatted(.number.precision(.fractionLength(1))))")
            Text("Seller reviews")
            Text("Active listings")
            PrimaryButton(title: "Contact Seller") {}
        }
        .navigationTitle("Seller")
    }
}
