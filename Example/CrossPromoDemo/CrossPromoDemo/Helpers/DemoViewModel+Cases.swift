import CrossPromoKit
import Foundation

/// The record of the last verification case that was set up.
///
/// "Ran" here means the setup steps were performed — never that the behaviour
/// under test was correct. The verdicts live in ``observations``, and only the
/// ones ``DemoObservation/isJudged`` marks carry a claim.
struct DemoCaseRun {
    /// The case that was set up.
    let verificationCase: DemoVerificationCase
    /// When the setup finished, so a stale panel is recognisable as stale.
    let ranAt: Date
    /// The catalog file version the setup put into the cache, when it seeded
    /// one. The later "did anything replace the cache?" observations are
    /// comparisons against this number.
    var seededVersion: Int?
    /// The readings and verdicts, refreshed every time the detail appears.
    var observations: [DemoObservationResult] = []
}

extension DemoViewModel {
    // MARK: - Running a case

    /// Performs every setup step of a case, in order, then takes a first
    /// reading.
    ///
    /// Steps run sequentially and the scenario is always selected first, so the
    /// cache operations that follow are scoped to the catalog the case is about.
    /// - Parameter verificationCase: The case to set up.
    func run(_ verificationCase: DemoVerificationCase) async {
        var run = DemoCaseRun(verificationCase: verificationCase, ranAt: Date())

        for action in verificationCase.actions {
            switch action {
            case .selectScenario(let scenario):
                self.scenario = scenario
            case .restoreCatalogFile:
                catalogStore.restoreFile()
            case .deleteCatalogFile:
                catalogStore.deleteFile()
            case .bumpCatalogVersion:
                catalogStore.bumpVersion()
            case .clearCache:
                await cacheManager(for: scenario)?.clearCache()
            case .seedCacheFromCatalog:
                if await seedCacheFromCatalog() {
                    run.seededVersion = catalogStore.version
                }
            case .expireCache:
                await cacheManager(for: scenario)?.expire()
            case .clearEvents:
                eventHandler.clear()
            case .remountList:
                listGeneration += 1
            }
        }

        caseRun = run
        await refreshCacheStatus()
        await refreshObservations()
    }

    /// Writes the catalog at the current URL into its cache, byte for byte as a
    /// successful fetch would have.
    ///
    /// `PromoService` caches the catalog it decoded, unfiltered, so decoding the
    /// same file and saving it produces the same cache entry — without needing
    /// the list on screen first. That is what lets a case start from "there is a
    /// valid cache holding version N" as a precondition rather than as a step
    /// the person has to perform.
    /// - Returns: Whether a catalog was found and cached.
    private func seedCacheFromCatalog() async -> Bool {
        guard let url = catalogURL(for: scenario),
              let catalog = catalog(at: url),
              let cacheManager = cacheManager(for: scenario) else { return false }
        await cacheManager.save(catalog)
        return true
    }

    /// Decodes the catalog at a URL, for the demo's own reading.
    ///
    /// Only local URLs answer; a remote catalog is not something the demo can
    /// read without becoming a second network client, and none of the
    /// observations need it.
    private func catalog(at url: URL) -> AppCatalog? {
        guard url.isFileURL, let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(AppCatalog.self, from: data)
    }

    // MARK: - Observations

    /// Re-reads everything the current case's observations are derived from.
    ///
    /// Called when the detail appears as well as after the setup, because most
    /// of them only become answerable once the person has been to the list.
    func refreshObservations() async {
        guard var run = caseRun else { return }
        var results: [DemoObservationResult] = []
        for observation in run.verificationCase.observations {
            results.append(await evaluate(observation, in: run))
        }
        run.observations = results
        caseRun = run
    }

    private func evaluate(_ observation: DemoObservation, in run: DemoCaseRun) async -> DemoObservationResult {
        switch observation {
        case .cacheState:
            await refreshCacheStatus()
            return DemoObservationResult(observation: observation, verdict: .reported, detail: cacheStatus)
        case .catalogFileState:
            return catalogFileStateResult(observation)
        case .cacheVersusFile:
            return await cacheVersusFileResult(observation)
        case .expectedRows:
            return expectedRowsResult(observation)
        case .renderedRows:
            return renderedRowsResult(observation)
        case .impressionsPerApp:
            return impressionsPerAppResult(observation)
        case .tapsRecorded:
            return DemoObservationResult(
                observation: observation,
                verdict: .reported,
                value: String(eventHandler.entries.filter { $0.kind == .tap }.count)
            )
        case .cacheKeptWhileStale:
            return await cacheKeptWhileStaleResult(observation)
        case .cacheDropped:
            return await cacheDroppedResult(observation)
        case .cacheUntouchedByLoad:
            return await cacheUntouchedResult(observation, seeded: run.seededVersion)
        case .cacheMatchesFile:
            return await cacheMatchesFileResult(observation, seeded: run.seededVersion)
        case .scopesIndependent:
            return await scopesIndependentResult(observation, seeded: run.seededVersion)
        }
    }

    // MARK: - Readings

    private func catalogFileStateResult(_ observation: DemoObservation) -> DemoObservationResult {
        guard catalogStore.fileExists else {
            return DemoObservationResult(observation: observation, verdict: .reported, detail: "Missing")
        }
        return DemoObservationResult(
            observation: observation,
            verdict: .reported,
            value: "v\(catalogStore.version)"
        )
    }

    private func cacheVersusFileResult(_ observation: DemoObservation) async -> DemoObservationResult {
        let cached = await cachedVersion()
        let cachedText = cached.map { "v\($0)" } ?? "—"
        let fileText = catalogStore.fileExists ? "v\(catalogStore.version)" : "—"
        return DemoObservationResult(
            observation: observation,
            verdict: .reported,
            value: "\(cachedText) / \(fileText)"
        )
    }

    private func expectedRowsResult(_ observation: DemoObservation) -> DemoObservationResult {
        guard let expected = expectedAppIDs(), !expected.isEmpty else {
            return DemoObservationResult(
                observation: observation,
                verdict: .reported,
                detail: "This catalog cannot be read from here."
            )
        }
        return DemoObservationResult(
            observation: observation,
            verdict: .reported,
            value: expected.joined(separator: ", ")
        )
    }

    // MARK: - Verdicts

    private func renderedRowsResult(_ observation: DemoObservation) -> DemoObservationResult {
        let rendered = impressionedAppIDs()
        guard !rendered.isEmpty else {
            return DemoObservationResult(observation: observation, verdict: .pending, detail: waitingForTheList)
        }
        guard let expected = expectedAppIDs() else {
            return DemoObservationResult(
                observation: observation,
                verdict: .reported,
                value: rendered.joined(separator: ", ")
            )
        }
        let verdict: DemoVerdict = Set(rendered) == Set(expected) ? .pass : .fail
        // Listed in the expected order rather than the order the impressions
        // arrived in: rows report themselves as they appear, which is not the
        // order they are laid out in, and a jumbled list here would read as an
        // ordering bug. Whether the rows are *in* catalog order is the eye check
        // this case carries, and stays one.
        let ordered = expected.filter(rendered.contains) + rendered.filter { !expected.contains($0) }
        return DemoObservationResult(
            observation: observation,
            verdict: verdict,
            value: ordered.joined(separator: ", "),
            detail: verdict == .pass ? nil : "This is not the set the catalog file calls for."
        )
    }

    private func impressionsPerAppResult(_ observation: DemoObservation) -> DemoObservationResult {
        let impressions = eventHandler.entries.filter { $0.kind == .impression }.map(\.appID)
        guard !impressions.isEmpty else {
            return DemoObservationResult(observation: observation, verdict: .pending, detail: waitingForTheList)
        }
        let unique = Set(impressions)
        return DemoObservationResult(
            observation: observation,
            verdict: impressions.count == unique.count ? .pass : .fail,
            value: "\(impressions.count) / \(unique.count)",
            detail: impressions.count == unique.count ? nil : "Some app was reported more than once in this session."
        )
    }

    private func cacheKeptWhileStaleResult(_ observation: DemoObservation) async -> DemoObservationResult {
        guard let cacheManager = cacheManager(for: scenario) else {
            return DemoObservationResult(observation: observation, verdict: .pending, detail: noCatalogURL)
        }
        let hasData = await cacheManager.hasCachedData()
        let expired = await cacheManager.isExpired()
        return DemoObservationResult(
            observation: observation,
            verdict: hasData && expired ? .pass : .fail,
            detail: cacheStatus
        )
    }

    private func cacheDroppedResult(_ observation: DemoObservation) async -> DemoObservationResult {
        guard let cacheManager = cacheManager(for: scenario) else {
            return DemoObservationResult(observation: observation, verdict: .pending, detail: noCatalogURL)
        }
        let hasData = await cacheManager.hasCachedData()
        return DemoObservationResult(
            observation: observation,
            verdict: hasData ? .fail : .pass,
            detail: cacheStatus
        )
    }

    private func cacheUntouchedResult(
        _ observation: DemoObservation,
        seeded: Int?
    ) async -> DemoObservationResult {
        guard let seeded else {
            return DemoObservationResult(observation: observation, verdict: .pending, detail: setupDidNotSeed)
        }
        guard !impressionedAppIDs().isEmpty else {
            return DemoObservationResult(observation: observation, verdict: .pending, detail: waitingForTheList)
        }
        let cached = await cachedVersion()
        let matches = cached == seeded
        return DemoObservationResult(
            observation: observation,
            verdict: matches ? .pass : .fail,
            value: "\(cached.map { "v\($0)" } ?? "—") / v\(seeded)",
            detail: matches
                ? "Still the version the setup cached; a fetch would have replaced it."
                : "Something fetched and re-cached the catalog even though the cache was valid."
        )
    }

    private func cacheMatchesFileResult(
        _ observation: DemoObservation,
        seeded: Int?
    ) async -> DemoObservationResult {
        let cached = await cachedVersion()
        let file = catalogStore.version
        let value = "\(cached.map { "v\($0)" } ?? "—") / v\(file)"
        if cached == file {
            return DemoObservationResult(observation: observation, verdict: .pass, value: value)
        }
        if let seeded, cached == seeded {
            return DemoObservationResult(
                observation: observation,
                verdict: .pending,
                value: value,
                detail: "No refresh has landed yet — the cache is still the one the setup wrote."
            )
        }
        return DemoObservationResult(
            observation: observation,
            verdict: .fail,
            value: value,
            detail: "The cache holds neither the seeded version nor the file's."
        )
    }

    private func scopesIndependentResult(
        _ observation: DemoObservation,
        seeded: Int?
    ) async -> DemoObservationResult {
        guard let seeded, let seededScope = cacheManager(for: .catalog),
              let currentScope = cacheManager(for: scenario) else {
            return DemoObservationResult(observation: observation, verdict: .pending, detail: setupDidNotSeed)
        }
        guard await currentScope.hasCachedData() else {
            return DemoObservationResult(observation: observation, verdict: .pending, detail: waitingForTheList)
        }
        let untouched = await version(in: seededScope) == seeded
        return DemoObservationResult(
            observation: observation,
            verdict: untouched ? .pass : .fail,
            detail: untouched
                ? "This catalog filled its own entry while the other one kept the version the setup cached."
                : "Loading this catalog changed the other catalog's cache entry."
        )
    }

    // MARK: - Sources

    /// The app IDs the current scenario's catalog file should produce.
    ///
    /// Worked out from the file the package is pointed at, by the two rules the
    /// catalog format defines: the host app is never promoted, and `promoRules`
    /// narrows the rest. Written here independently of the package so that
    /// comparing it against the impressions the package reports is a check and
    /// not an echo.
    func expectedAppIDs() -> [String]? {
        guard let url = catalogURL(for: scenario), let catalog = catalog(at: url) else { return nil }
        var ids = catalog.apps.map(\.id).filter { $0 != Self.currentAppID }
        if let rules = catalog.promoRules?[Self.currentAppID] {
            ids = ids.filter { rules.contains($0) }
        }
        return ids
    }

    /// The app IDs the package reported impressions for.
    ///
    /// Oldest first, which is arrival order — rows report themselves as they
    /// come on screen, and that is not the order they are laid out in. Only
    /// membership is meaningful here; the layout order is an eye check.
    private func impressionedAppIDs() -> [String] {
        Array(eventHandler.entries.filter { $0.kind == .impression }.map(\.appID).reversed())
    }

    /// The catalog file version currently sitting in the cache for the selected
    /// scenario, if the cached catalog carries the demo's version row.
    private func cachedVersion() async -> Int? {
        guard let cacheManager = cacheManager(for: scenario) else { return nil }
        return await version(in: cacheManager)
    }

    private func version(in cacheManager: CacheManager) async -> Int? {
        guard let catalog = await cacheManager.load() else { return nil }
        return DemoCatalogStore.version(in: catalog)
    }

    // MARK: - Shared phrasing

    private var waitingForTheList: LocalizedStringResource {
        "Nothing to judge yet — the package has not reported rendering anything since the setup. Open the list and come back."
    }

    private var noCatalogURL: LocalizedStringResource {
        "No catalog URL for this scenario yet."
    }

    private var setupDidNotSeed: LocalizedStringResource {
        "The setup did not cache a catalog, so there is no version to compare against."
    }
}
