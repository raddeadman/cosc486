import Foundation
import Combine

final class AddProductViewModel: ObservableObject {
    @Published var selectedImages: [Data] = []
    @Published var title = ""
    @Published var description = ""
    @Published var category = Constants.categories.first ?? "General"
    @Published var priceText = ""
    @Published var locationName = ""
    @Published var isSubmitting = false

    private let productService = ProductService()

    func submitProduct() {
        guard validate() else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        productService.submitPlaceholderProduct(
            title: title,
            description: description,
            category: category,
            priceText: priceText,
            locationName: locationName
        )
    }

    func validate() -> Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            Double(priceText) != nil &&
            !locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
