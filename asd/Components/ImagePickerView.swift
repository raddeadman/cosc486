import SwiftUI
import PhotosUI

struct ImagePickerView: View {
    @Binding var selectedImages: [Data]
    @State private var pickerItems: [PhotosPickerItem] = []

    var body: some View {
        PhotosPicker(
            selection: $pickerItems,
            maxSelectionCount: 6,
            matching: .images
        ) {
            Label("Select Images", systemImage: "photo.on.rectangle.angled")
        }
        .onChange(of: pickerItems) {
            Task {
                var loadedData: [Data] = []
                for item in pickerItems {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        loadedData.append(data)
                    }
                }
                selectedImages = loadedData
            }
        }
    }
}
