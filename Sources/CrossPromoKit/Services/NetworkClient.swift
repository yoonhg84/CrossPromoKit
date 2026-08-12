import Foundation

/// Network client for fetching the app catalog from remote endpoint.
///
/// ## Timeouts and retries
///
/// The client adds no timeout or retry policy of its own; it inherits whatever
/// the session it was given is configured with. With the default
/// `URLSession.shared` that means a 60-second per-request timeout and a 7-day
/// resource timeout, and a failed request is **not** retried: ``PromoService``
/// treats any failure as its cue to fall back to the cache rather than to try
/// again. To use different limits, pass a session configured with your own
/// `timeoutIntervalForRequest` / `timeoutIntervalForResource`.
public actor NetworkClient {
    private let urlSession: URLSession

    /// Creates a client backed by the given session.
    /// - Parameter urlSession: The session used for every fetch. Its
    ///   configuration determines timeout behaviour — see the type's discussion.
    ///   Defaults to `URLSession.shared`.
    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    /// Fetches the app catalog from the specified URL.
    /// - Parameter url: The URL to fetch the catalog from (supports both http(s):// and file:// URLs)
    /// - Returns: The decoded AppCatalog
    /// - Throws: NetworkError if the request fails or data is invalid
    public func fetchCatalog(from url: URL) async throws -> AppCatalog {
        let (data, response) = try await urlSession.data(from: url)

        // Handle based on URL scheme
        if url.isFileURL {
            // For file URLs: just validate we got data
            guard !data.isEmpty else {
                throw NetworkError.noData
            }
        } else {
            // For HTTP(S): validate HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.httpError(statusCode: httpResponse.statusCode)
            }
        }

        // Decode regardless of source
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
