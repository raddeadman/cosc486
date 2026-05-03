import Foundation
import Combine

struct AuthenticatedRequest {
    static func make(urlString: String, method: String = "GET", body: [String: Any]? = nil) -> AnyPublisher<Data, Error> {
        guard let token = TokenManager.get() else {
            return Fail(error: NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authentication token"]))
                .eraseToAnyPublisher()
        }

        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { $0.data }
            .eraseToAnyPublisher()
    }
}