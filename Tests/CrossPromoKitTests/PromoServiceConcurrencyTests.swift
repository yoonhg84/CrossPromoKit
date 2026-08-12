@testable import CrossPromoKit
import Foundation
import Testing

/// Answers catalog requests in order, holding the first one open until the test
/// releases it, so a second call can be made while a load is genuinely in flight.
///
/// It carries its own responder slot rather than reusing ``StubURLProtocol``'s
/// global one so this suite cannot race the NetworkClient suites.
final class GatedURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) private static var responder: GatedURLProtocol.Responder?

    final class Responder: @unchecked Sendable {
        private let lock = NSLock()
        private let gate = DispatchSemaphore(value: 0)
        private let bodies: [Data]
        private var served = 0

        /// - Parameter bodies: Response bodies, one per request in arrival order.
        ///   The last one repeats if more requests arrive.
        init(bodies: [Data]) {
            self.bodies = bodies
        }

        /// Number of requests that have reached the protocol so far.
        var requestCount: Int {
            lock.withLock { served }
        }

        /// Lets the first (held) request complete.
        func release() {
            gate.signal()
        }

        fileprivate func body(for index: Int) -> Data {
            bodies[min(index, bodies.count - 1)]
        }

        fileprivate func claimIndex() -> Int {
            lock.withLock {
                served += 1
                return served - 1
            }
        }

        fileprivate func waitIfFirst(_ index: Int) {
            if index == 0 { gate.wait() }
        }
    }

    /// Installs a session answered by a fresh responder, returned alongside it.
    static func makeSession(bodies: [Data]) -> (URLSession, Responder) {
        let responder = Responder(bodies: bodies)
        Self.responder = responder
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [GatedURLProtocol.self]
        return (URLSession(configuration: configuration), responder)
    }

    static func reset() {
        responder = nil
    }

    override static func canInit(with request: URLRequest) -> Bool { true }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let responder = Self.responder else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }

        let index = responder.claimIndex()
        responder.waitIfFirst(index)

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: responder.body(for: index))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

/// Records a value observed from inside a concurrently started task.
@MainActor
final class ObservedFlag {
    var value = false
}

@Suite("PromoService concurrent loads", .serialized)
@MainActor
struct PromoServiceConcurrencyTests {
    private let jsonURL = URL(string: "https://example.com/concurrent-apps.json")!

    private func makeService(session: URLSession, storage: IsolatedDefaults) -> PromoService {
        PromoService(
            config: PromoConfig(jsonURL: jsonURL, currentAppID: "host"),
            networkClient: NetworkClient(urlSession: session),
            cacheManager: CacheManager(scope: jsonURL, userDefaults: storage.make())
        )
    }

    /// Polls `condition` on the main actor, failing rather than hanging forever.
    private func waitUntil(
        _ description: Comment,
        _ condition: () -> Bool
    ) async throws {
        let deadline = ContinuousClock.now + .seconds(5)
        while !condition() {
            guard ContinuousClock.now < deadline else {
                Issue.record("Timed out waiting for \(description)")
                return
            }
            try await Task.sleep(for: .milliseconds(5))
        }
    }

    @Test("forceRefresh requested during a load is not dropped")
    func forceRefreshDuringLoadStillFetches() async throws {
        let storage = IsolatedDefaults()
        defer { storage.remove() }
        let (session, responder) = GatedURLProtocol.makeSession(bodies: [
            try Fixture.json(for: Fixture.catalog(ids: ["host", "first"])),
            try Fixture.json(for: Fixture.catalog(ids: ["host", "second"]))
        ])
        defer { GatedURLProtocol.reset() }
        let service = makeService(session: session, storage: storage)

        let load = Task { await service.loadApps() }
        try await waitUntil("the first load to start") { service.isLoading }

        // Started while the first fetch is still held open by the gate.
        let sawLoadInFlight = ObservedFlag()
        let refresh = Task { @MainActor in
            sawLoadInFlight.value = service.isLoading
            await service.forceRefresh()
        }
        await Task.yield()
        responder.release()
        await load.value
        await refresh.value

        #expect(sawLoadInFlight.value == true)
        #expect(responder.requestCount == 2)
        #expect(service.apps.map(\.id) == ["second"])
    }

    @Test("A second loadApps during a load is coalesced into the running one")
    func concurrentLoadAppsIsCoalesced() async throws {
        let storage = IsolatedDefaults()
        defer { storage.remove() }
        let (session, responder) = GatedURLProtocol.makeSession(bodies: [
            try Fixture.json(for: Fixture.catalog(ids: ["host", "first"])),
            try Fixture.json(for: Fixture.catalog(ids: ["host", "second"]))
        ])
        defer { GatedURLProtocol.reset() }
        let service = makeService(session: session, storage: storage)

        let load = Task { await service.loadApps() }
        try await waitUntil("the first load to start") { service.isLoading }

        // Returns immediately without waiting for, or duplicating, the fetch.
        await service.loadApps()
        #expect(service.isLoading == true)
        #expect(responder.requestCount == 1)

        responder.release()
        await load.value

        #expect(responder.requestCount == 1)
        #expect(service.apps.map(\.id) == ["first"])
    }

    @Test("Sequential forceRefresh calls each perform their own fetch")
    func sequentialForceRefreshesEachFetch() async throws {
        let storage = IsolatedDefaults()
        defer { storage.remove() }
        let (session, responder) = GatedURLProtocol.makeSession(bodies: [
            try Fixture.json(for: Fixture.catalog(ids: ["host", "first"])),
            try Fixture.json(for: Fixture.catalog(ids: ["host", "second"]))
        ])
        defer { GatedURLProtocol.reset() }
        let service = makeService(session: session, storage: storage)
        responder.release()  // nothing is held open in this scenario

        await service.loadApps()
        #expect(service.apps.map(\.id) == ["first"])

        await service.forceRefresh()

        #expect(responder.requestCount == 2)
        #expect(service.apps.map(\.id) == ["second"])
        #expect(service.isLoading == false)
    }
}
