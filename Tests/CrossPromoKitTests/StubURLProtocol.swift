import Foundation

/// URLProtocol stub that answers requests from an in-process responder closure.
///
/// The responder is global mutable state, so suites using it must be
/// `.serialized`.
final class StubURLProtocol: URLProtocol {
    /// Produces the response and body for a request, or throws a transport error.
    nonisolated(unsafe) static var responder: (@Sendable (URLRequest) throws -> (URLResponse, Data))?

    /// Installs a session whose requests are answered by `responder`.
    static func makeSession(
        responder: @escaping @Sendable (URLRequest) throws -> (URLResponse, Data)
    ) -> URLSession {
        Self.responder = responder
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    /// Convenience responder returning an HTTP response with the given status and body.
    static func makeSession(statusCode: Int, body: Data) -> URLSession {
        makeSession { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, body)
        }
    }

    static func reset() {
        responder = nil
    }

    // MARK: - URLProtocol

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let responder = Self.responder else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }

        do {
            let (response, data) = try responder(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if !data.isEmpty {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
