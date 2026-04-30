import Foundation
import Combine

// MARK: - Storage Service
// Handles all storage-related operations with the backend API

enum StorageError: Error, LocalizedError {
    case invalidParameters
    case networkError(Error)
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidParameters:
            return "Invalid parameters provided"
        case .networkError(let error):
            return error.localizedDescription
        case .serverError(let message):
            return message
        }
    }
}

final class StorageService {
    private let baseURL = "https://api.example.com/v1"

    // MARK: - Upload Image Data

    func uploadImageData(file: Data, fileName: String) -> AnyPublisher<UploadResponse, Error> {
        guard !file.isEmpty else {
            return Fail(error: StorageError.invalidParameters).eraseToAnyPublisher()
        }

        let urlString = "\(baseURL)/uploads/images"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data", forHTTPHeaderField: "Content-Type")

        // Create multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name="file"; filename=\\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!) // Assuming JPEG, adjust if needed
        body.append(file)

        // Close the multipart form
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap(\.response)
            .decode(type: UploadResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQuery.main)
            .eraseToAnyPublisher()
    }
}

// MARK: - Response Models

struct UploadResponse: Codable {
    let url: String
}
