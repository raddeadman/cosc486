import Foundation

final class StorageService {
    func uploadImageData(_ data: Data) async throws -> String {
        _ = data
        return "https://example.com/image.jpg"
    }
}
