import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct AddProductView: View {
    @StateObject private var viewModel = AddProductViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                sectionCard(title: "Photos") {
                    ImagePickerView(selectedImages: $viewModel.selectedImages)
                    if !viewModel.selectedImages.isEmpty {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], spacing: 8) {
                            ForEach(Array(viewModel.selectedImages.enumerated()), id: \.offset) { _, data in
#if canImport(UIKit)
                                if let ui = UIImage(data: data) {
                                    Image(uiImage: ui)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 72, height: 72)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
#else
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.secondarySystemFill))
                                    .frame(width: 72, height: 72)
#endif
                            }
                        }
                        .padding(.top, 6)
                    }
                }

                sectionCard(title: "Details") {
                    TextField("Title", text: $viewModel.title)
                        .textFieldStyle(.roundedBorder)
                    TextField("Description", text: $viewModel.description, axis: .vertical)
                        .lineLimit(8...16)
                        .frame(minHeight: 140, alignment: .topLeading)
                        .textFieldStyle(.roundedBorder)
                    Picker("Category", selection: $viewModel.category) {
                        ForEach(Constants.categories, id: \.self, content: Text.init)
                    }
                    TextField("Price", text: $viewModel.priceText)
#if os(iOS)
                        .keyboardType(.decimalPad)
#endif
                        .textFieldStyle(.roundedBorder)
                }

                sectionCard(title: "Location") {
                    ProductLocationPickerView(viewModel: viewModel)
                }

                PrimaryButton(title: "Submit product", isLoading: viewModel.isSubmitting) {
                    viewModel.submitProduct()
                }

                if let message = viewModel.submissionMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundColor(viewModel.submissionIsError ? .red : .green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .navigationTitle("Add Product")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionCard(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
