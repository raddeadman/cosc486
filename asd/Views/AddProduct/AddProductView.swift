import SwiftUI

struct AddProductView: View {
    @StateObject private var viewModel = AddProductViewModel()

    var body: some View {
        Form {
            Section("Images") {
                ImagePickerView(selectedImages: $viewModel.selectedImages)
            }

            Section("Details") {
                TextField("Title", text: $viewModel.title)
                TextField("Description", text: $viewModel.description, axis: .vertical)
                Picker("Category", selection: $viewModel.category) {
                    ForEach(Constants.categories, id: \.self, content: Text.init)
                }
                TextField("Price", text: $viewModel.priceText)
#if os(iOS)
                    .keyboardType(.decimalPad)
#endif
            }

            Section("Location") {
                ProductLocationPickerView(viewModel: viewModel)
            }

            PrimaryButton(title: "Submit product", isLoading: viewModel.isSubmitting) {
                viewModel.submitProduct()
            }

            if let message = viewModel.submissionMessage {
                Section {
                    Text(message)
                        .foregroundColor(viewModel.submissionIsError ? .red : .green)
                        .font(.footnote)
                }
            }
        }
        .navigationTitle("Add Product")
    }
}
