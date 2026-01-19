import Foundation

/// Network client for fetching the app catalog from remote endpoint.
public actor NetworkClient {
    private let urlSession: URLSession

    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    /// Fetches the app catalog from the specified URL.
    /// - Parameter url: The URL to fetch the catalog from
    /// - Returns: The decoded AppCatalog
    /// - Throws: NetworkError if the request fails or data is invalid
    public func fetchCatalog(from url: URL) async throws -> AppCatalog {
        let (data, response) = try await urlSession.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(AppCatalog.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
}

/// Errors that can occur during network operations.
public enum NetworkError: Error, Sendable, Equatable {
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case noData

    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidResponse, .invalidResponse):
            return true
        case (.httpError(let lhsCode), .httpError(let rhsCode)):
            return lhsCode == rhsCode
        case (.decodingError, .decodingError):
            return true
        case (.noData, .noData):
            return true
        default:
            return false
        }
    }
}
