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
    private let baseURL = "https://us-central1-openmarketmobile.cloudfunctions.net"

    // MARK: - Upload Image Data

    func uploadImageData(file: Data, fileName: String) -> AnyPublisher<UploadResponse, Error> {
        guard !file.isEmpty else {
            return Fail(error: StorageError.invalidParameters).eraseToAnyPublisher()
        }

        let urlString = "\(baseURL)/uploadImageData"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "POST"

        if let token = TokenManager.get() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Create multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // RFC 5987-style safety: quote filename and escape `\` / `"` so multipart headers stay valid.
        let escapedName = fileName
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(escapedName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(file)

        // Close the multipart form
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body
        request.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { output in
                guard let http = output.response as? HTTPURLResponse else {
                    throw StorageError.serverError("Invalid server response")
                }
                guard (200...299).contains(http.statusCode) else {
                    let text = String(data: output.data, encoding: .utf8) ?? "Upload failed"
                    throw StorageError.serverError(text)
                }
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(UploadResponse.self, from: output.data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// MARK: - Response Models

struct UploadResponse: Codable {
    let url: String
}

