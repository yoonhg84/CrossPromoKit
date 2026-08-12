import Foundation
import Testing
@testable import CrossPromoKit

@Suite("NetworkClient — file:// URLs")
struct NetworkClientFileTests {
    @Test("Decodes a catalog from a file URL")
    func decodesFromFile() async throws {
        let catalog = Fixture.catalog(ids: ["finebill", "pocketstash"], promoRules: ["host": ["finebill"]])
        let url = try makeTemporaryFile(contents: try Fixture.json(for: catalog))
        defer { removeTemporaryFile(at: url) }

        let fetched = try await NetworkClient().fetchCatalog(from: url)

        #expect(fetched == catalog)
    }

    @Test("Empty file throws noData")
    func emptyFileThrowsNoData() async throws {
        let url = try makeTemporaryFile(contents: Data())
        defer { removeTemporaryFile(at: url) }

        await #expect(throws: NetworkError.noData) {
            try await NetworkClient().fetchCatalog(from: url)
        }
    }

    @Test("Malformed JSON in a file throws decodingError")
    func malformedFileThrowsDecodingError() async throws {
        let url = try makeTemporaryFile(contents: Data(#"{"apps": "not an array"}"#.utf8))
        defer { removeTemporaryFile(at: url) }

        await #expect(throws: NetworkError.decodingError(NetworkError.noData)) {
            try await NetworkClient().fetchCatalog(from: url)
        }
    }

    @Test("Missing file surfaces the underlying URL error, not a NetworkError")
    func missingFileThrows() async {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("CrossPromoKitTests-missing-\(UUID().uuidString).json")

        await #expect(throws: (any Error).self) {
            try await NetworkClient().fetchCatalog(from: url)
        }
    }
}

@Suite("NetworkClient — HTTP", .serialized)
struct NetworkClientHTTPTests {
    private let remoteURL = URL(string: "https://example.com/apps.json")!

    private func client(session: URLSession) -> NetworkClient {
        NetworkClient(urlSession: session)
    }

    @Test("Decodes a catalog from a 200 response")
    func decodesFromSuccessResponse() async throws {
        defer { StubURLProtocol.reset() }
        let catalog = Fixture.catalog(ids: ["finebill", "pocketstash"])
        let session = StubURLProtocol.makeSession(statusCode: 200, body: try Fixture.json(for: catalog))

        let fetched = try await client(session: session).fetchCatalog(from: remoteURL)

        #expect(fetched == catalog)
    }

    @Test("Accepts the whole 2xx range", arguments: [200, 201, 202, 299])
    func acceptsSuccessRange(statusCode: Int) async throws {
        defer { StubURLProtocol.reset() }
        let catalog = Fixture.catalog(ids: ["finebill"])
        let session = StubURLProtocol.makeSession(statusCode: statusCode, body: try Fixture.json(for: catalog))

        let fetched = try await client(session: session).fetchCatalog(from: remoteURL)

        #expect(fetched == catalog)
    }

    @Test("Non-2xx status throws httpError with the status code", arguments: [301, 400, 403, 404, 500, 503])
    func nonSuccessStatusThrowsHTTPError(statusCode: Int) async throws {
        defer { StubURLProtocol.reset() }
        let session = StubURLProtocol.makeSession(
            statusCode: statusCode,
            body: try Fixture.json(for: Fixture.catalog(ids: ["finebill"]))
        )

        await #expect(throws: NetworkError.httpError(statusCode: statusCode)) {
            try await client(session: session).fetchCatalog(from: remoteURL)
        }
    }

    @Test("Status is checked before decoding")
    func statusIsCheckedBeforeDecoding() async {
        defer { StubURLProtocol.reset() }
        let session = StubURLProtocol.makeSession(statusCode: 500, body: Data("<html>oops</html>".utf8))

        await #expect(throws: NetworkError.httpError(statusCode: 500)) {
            try await client(session: session).fetchCatalog(from: remoteURL)
        }
    }

    @Test("A non-HTTP response throws invalidResponse")
    func nonHTTPResponseThrowsInvalidResponse() async {
        defer { StubURLProtocol.reset() }
        let session = StubURLProtocol.makeSession { request in
            let response = URLResponse(
                url: request.url!,
                mimeType: "application/json",
                expectedContentLength: 2,
                textEncodingName: nil
            )
            return (response, Data("{}".utf8))
        }

        await #expect(throws: NetworkError.invalidResponse) {
            try await client(session: session).fetchCatalog(from: remoteURL)
        }
    }

    @Test("Malformed JSON throws decodingError")
    func malformedJSONThrowsDecodingError() async {
        defer { StubURLProtocol.reset() }
        let session = StubURLProtocol.makeSession(statusCode: 200, body: Data(#"{"unexpected": true}"#.utf8))

        await #expect(throws: NetworkError.decodingError(NetworkError.noData)) {
            try await client(session: session).fetchCatalog(from: remoteURL)
        }
    }

    @Test("Transport failures propagate to the caller")
    func transportFailurePropagates() async {
        defer { StubURLProtocol.reset() }
        let session = StubURLProtocol.makeSession { _ in throw URLError(.notConnectedToInternet) }

        await #expect(throws: (any Error).self) {
            try await client(session: session).fetchCatalog(from: remoteURL)
        }
    }
}

@Suite("NetworkError equality")
struct NetworkErrorTests {
    @Test("httpError compares by status code")
    func httpErrorComparesByStatusCode() {
        #expect(NetworkError.httpError(statusCode: 404) == NetworkError.httpError(statusCode: 404))
        #expect(NetworkError.httpError(statusCode: 404) != NetworkError.httpError(statusCode: 500))
    }

    @Test("decodingError ignores the wrapped error")
    func decodingErrorIgnoresWrappedError() {
        #expect(NetworkError.decodingError(NetworkError.noData) == NetworkError.decodingError(URLError(.badURL)))
    }

    @Test("Different cases are not equal")
    func differentCasesAreNotEqual() {
        #expect(NetworkError.noData != NetworkError.invalidResponse)
        #expect(NetworkError.invalidResponse != NetworkError.httpError(statusCode: 200))
    }
}
