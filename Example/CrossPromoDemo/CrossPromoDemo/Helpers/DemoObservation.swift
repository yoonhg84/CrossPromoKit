import Foundation

/// Something the demo can read for itself after a case has run.
///
/// The demo has exactly three windows onto the package's behaviour: the
/// `CacheManager` it builds for the same catalog URL, the catalog file it owns,
/// and the events the package hands it through `PromoEventDelegate`. Everything
/// inside `MoreAppsView`'s `PromoService` — how many apps it holds, whether it
/// went to the network, which error it caught — is invisible from here.
///
/// So only a few of these carry a verdict. ``isJudged`` marks the ones where a
/// pass or a fail means the behaviour was right; the rest are reported values,
/// shown without a mark, for the person comparing them against the screen.
enum DemoObservation: String, Identifiable {
    /// Whether a cache exists for the current catalog URL, and how old it is.
    case cacheState
    /// Whether the editable catalog file is on disk, and at which version.
    case catalogFileState
    /// The version in the cache next to the version on disk — the pair the
    /// `Catalog v…` row in the list is compared against.
    case cacheVersusFile
    /// The app IDs the catalog file should produce, in file order.
    case expectedRows
    /// The app IDs the package reported impressions for, against ``expectedRows``.
    case renderedRows
    /// Whether any app was reported more than once.
    case impressionsPerApp
    /// How many taps the package reported.
    case tapsRecorded
    /// Whether `expire()` left the data in place while marking it stale.
    case cacheKeptWhileStale
    /// Whether `clearCache()` really left nothing behind.
    case cacheDropped
    /// Whether the cached catalog is still the one the setup put there.
    case cacheUntouchedByLoad
    /// Whether the cached catalog has caught up with the file.
    case cacheMatchesFile
    /// Whether two catalog URLs kept separate cache entries.
    case scopesIndependent

    var id: String { rawValue }

    var label: LocalizedStringResource {
        switch self {
        case .cacheState: return "Cache"
        case .catalogFileState: return "Catalog file"
        case .cacheVersusFile: return "Cached version vs. file version"
        case .expectedRows: return "Rows this catalog should produce"
        case .renderedRows: return "Rows the package reported rendering"
        case .impressionsPerApp: return "One impression per app"
        case .tapsRecorded: return "Taps reported"
        case .cacheKeptWhileStale: return "Expiring kept the data and marked it stale"
        case .cacheDropped: return "Nothing left in the cache to fall back on"
        case .cacheUntouchedByLoad: return "The load left the cached catalog alone"
        case .cacheMatchesFile: return "The cache now holds the file's version"
        case .scopesIndependent: return "Each catalog URL kept its own cache entry"
        }
    }

    /// Whether a pass here means the behaviour was right.
    ///
    /// False for the plain readings — a value with no claim attached.
    var isJudged: Bool {
        switch self {
        case .cacheState, .catalogFileState, .cacheVersusFile, .expectedRows, .tapsRecorded:
            return false
        case .renderedRows, .impressionsPerApp, .cacheKeptWhileStale, .cacheDropped,
             .cacheUntouchedByLoad, .cacheMatchesFile, .scopesIndependent:
            return true
        }
    }
}

/// The outcome of one observation.
enum DemoVerdict {
    /// The behaviour this observation covers happened.
    case pass
    /// It did not. Worth reporting as a bug.
    case fail
    /// Nothing to judge yet — usually because the list has not been opened, so
    /// the package has not done anything to observe.
    case pending
    /// A reading, not a claim.
    case reported
}

/// One observation together with what the demo found.
struct DemoObservationResult: Identifiable {
    let observation: DemoObservation
    let verdict: DemoVerdict
    /// Raw data — app IDs, version numbers — shown verbatim, not localized.
    var value: String?
    /// Prose about the outcome, when a number alone does not explain it.
    var detail: LocalizedStringResource?

    init(
        observation: DemoObservation,
        verdict: DemoVerdict,
        value: String? = nil,
        detail: LocalizedStringResource? = nil
    ) {
        self.observation = observation
        self.verdict = verdict
        self.value = value
        self.detail = detail
    }

    var id: String { observation.id }
}
