import Foundation

final class StorageService {
    func uploadImageData(_ data: Data) async throws -> String {
        // API placeholder:
        // POST https://api.example.com/v1/uploads/images (multipart/form-data)
        // Form field: "file" -> binary image data
        // Response: { "url": "https://cdn.example.com/..." }
        _ = data
        return "https://example.com/image.jpg"
    }
}
