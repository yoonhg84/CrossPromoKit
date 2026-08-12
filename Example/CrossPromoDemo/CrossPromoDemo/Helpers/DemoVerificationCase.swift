import Foundation

/// One thing worth checking, together with everything needed to get there.
///
/// The Debug tab holds the parts — scenarios, cache operations, catalog file
/// operations. A case is the recipe: an ordered list of those parts that puts
/// the app into the state where a behaviour becomes visible, so nobody has to
/// remember that the stale-cache fallback needs "load, expire, delete the file,
/// refresh" in that order.
///
/// A case never restates what ``DemoScenario/explanation`` already says about
/// the catalog it uses; ``purpose`` is nil whenever the scenario's own text is
/// the whole story.
enum DemoVerificationCase: String, CaseIterable, Identifiable {
    // List contents
    case selfExcluded
    case promoRules
    // States the package draws
    case loading
    case emptyCatalog
    case unreachable
    // Cache
    case cacheFirst
    case forceRefresh
    case staleFallback
    case clearedNoFallback
    case cacheScope
    // Config, events, overlay
    case configSwap
    case events
    case overlay
    // Presentation
    case icons
    case accessibility

    var id: String { rawValue }

    /// The section a case is listed under.
    enum Group: String, CaseIterable, Identifiable {
        case listContents
        case states
        case cache
        case configAndEvents
        case presentation

        var id: String { rawValue }

        var title: LocalizedStringResource {
            switch self {
            case .listContents: return "List contents"
            case .states: return "States the package draws"
            case .cache: return "Cache"
            case .configAndEvents: return "Config, events, overlay"
            case .presentation: return "Icons and accessibility"
            }
        }
    }

    var group: Group {
        switch self {
        case .selfExcluded, .promoRules: return .listContents
        case .loading, .emptyCatalog, .unreachable: return .states
        case .cacheFirst, .forceRefresh, .staleFallback, .clearedNoFallback, .cacheScope: return .cache
        case .configSwap, .events, .overlay: return .configAndEvents
        case .icons, .accessibility: return .presentation
        }
    }

    /// Cases in this group, in declaration order.
    static func cases(in group: Group) -> [DemoVerificationCase] {
        allCases.filter { $0.group == group }
    }

    // MARK: - Text

    var title: LocalizedStringResource {
        switch self {
        case .selfExcluded: return "Host app excluded, catalog order kept"
        case .promoRules: return "promoRules narrows the list"
        case .loading: return "Loading indicator"
        case .emptyCatalog: return "Empty catalog state"
        case .unreachable: return "Offline state"
        case .cacheFirst: return "A valid cache answers without a fetch"
        case .forceRefresh: return "Force refresh, from all three entry points"
        case .staleFallback: return "A stale cache survives a failed fetch"
        case .clearedNoFallback: return "Control: cleared cache leaves nothing to fall back on"
        case .cacheScope: return "Each catalog URL caches separately"
        case .configSwap: return "Swapping the config rebuilds the list"
        case .events: return "One impression per app, one event per tap"
        case .overlay: return "App Store overlay: shown, replaced, dismissed"
        case .icons: return "Remote icons and the placeholder"
        case .accessibility: return "VoiceOver and the three languages"
        }
    }

    /// What this case is for, when the scenario's own explanation does not
    /// already say it. Nil means ``DemoScenario/explanation`` covers it.
    var purpose: LocalizedStringResource? {
        switch self {
        case .selfExcluded:
            return "The host app never promotes itself, and the rows that remain keep the order the catalog file lists them in (FR-016)."
        case .cacheFirst:
            return "A cache younger than 24 hours is used as-is. The setup leaves a newer catalog on disk than the one in the cache, so a list showing the cached number is proof no fetch happened."
        case .forceRefresh:
            return "A forced refresh ignores a valid cache. Try each entry point in turn: the toolbar ↻, pull-to-refresh on the Settings list, and Force Refresh in the Debug tab."
        case .staleFallback:
            return "The cache is expired and the catalog file is gone, so the fetch fails. The stale list has to stand in for it instead of an empty state."
        case .clearedNoFallback:
            return "The same failed fetch as the previous case, minus the cache. This is the control that proves the stale list came from the cache and not from somewhere else."
        case .cacheScope:
            return "Two catalog URLs in one app keep independent cache entries, so loading one must not overwrite or answer for the other."
        case .configSwap:
            return "Run \"Host app excluded\" first and look at its list, then pick this one from the case menu. It hands the live promo view a different PromoConfig without rebuilding the view, which is the one thing that made the old catalog stick around."
        case .events:
            return "Scroll the rows above out of view and back a few times, then tap one row. The readings below re-read themselves as the events arrive."
        case .overlay:
            return "In the simulator SKOverlay usually cannot present, so the package falls back to its own \"Open in App Store\" alert. On a simulator that alert is the pass, not a failure."
        case .accessibility:
            return "Turn VoiceOver on (Settings → Accessibility → VoiceOver, or triple-click the side button) before going to the list."
        case .promoRules, .loading, .emptyCatalog, .unreachable, .icons:
            return nil
        }
    }

    /// Things only a person can decide, stated as precisely as the demo can
    /// state them. Never auto-judged — the demo cannot see inside the package's
    /// `PromoService`, so it cannot claim any of these passed.
    var eyeChecks: [LocalizedStringResource] {
        switch self {
        case .selfExcluded:
            return ["The rows appear in the same order as the expected list above."]
        case .promoRules:
            return []
        case .loading:
            return ["The list area keeps the package's spinner until the request times out — around a minute — instead of dropping to an empty state."]
        case .emptyCatalog:
            return [
                "The empty state reads \"No Apps Yet\" under an app.badge.fill icon.",
                "Nothing in the copy blames the network; that wording belongs to the offline state."
            ]
        case .unreachable:
            return [
                "The empty state reads \"You're Offline\" under a wifi.slash icon.",
                "Held next to the empty-catalog case, the two states are told apart at a glance."
            ]
        case .cacheFirst:
            return ["The Catalog v… row in the list shows the cached number above, not the file number."]
        case .forceRefresh:
            return [
                "After each entry point the Catalog v… row moves to the file number.",
                "Run the setup again between entry points so the next one has something new to fetch."
            ]
        case .staleFallback:
            return ["The old rows are there on arrival, and stay put through a pull-to-refresh; no offline state appears."]
        case .clearedNoFallback:
            return ["The offline state is there on arrival, and a pull-to-refresh does not bring the rows back."]
        case .cacheScope:
            return []
        case .configSwap:
            return ["The list is the promo-rules catalog now, not the one that was on screen a moment ago."]
        case .events:
            return []
        case .overlay:
            return [
                "Tap a row: the overlay — or the fallback alert — appears.",
                "Tap a different row while it is up: the previous one is replaced rather than stacked.",
                "Leave the screen while it is up: it goes away with the promo list."
            ]
        case .icons:
            return [
                "One HTTPS icon loads; the 404 and the unresolvable host both fall back to the package placeholder.",
                "The sf-symbol:// row draws the symbol itself rather than a placeholder."
            ]
        case .accessibility:
            return [
                "VoiceOver reads each promo row as one element — name, category and tagline together — not as three separate stops.",
                "The refresh button reads as \"Force Refresh\".",
                "Switch the app language from Debug → Open Language Settings and check en, ko and ja for clipped or untranslated text."
            ]
        }
    }

    // MARK: - Setup

    /// The scenario this case ends on; also the catalog whose
    /// ``DemoScenario/explanation`` the case detail reuses.
    var scenario: DemoScenario {
        switch self {
        case .selfExcluded, .cacheFirst, .forceRefresh, .staleFallback,
             .clearedNoFallback, .events, .overlay, .accessibility:
            return .catalog
        case .promoRules, .cacheScope, .configSwap:
            return .rules
        case .loading:
            return .stalled
        case .emptyCatalog:
            return .empty
        case .unreachable:
            return .offline
        case .icons:
            return .remoteIcons
        }
    }

    /// Everything the case does, in order, when Run Setup is tapped.
    ///
    /// The scenario is always selected first: the cache operations are scoped to
    /// the current catalog URL, so they would otherwise hit the wrong cache.
    var actions: [DemoCaseAction] {
        switch self {
        case .selfExcluded:
            return [.selectScenario(.catalog), .restoreCatalogFile, .clearCache, .clearEvents, .remountList]
        case .promoRules:
            return [.selectScenario(.rules), .clearCache, .clearEvents, .remountList]
        case .loading:
            return [.selectScenario(.stalled), .clearCache, .remountList]
        case .emptyCatalog:
            return [.selectScenario(.empty), .clearCache, .remountList]
        case .unreachable:
            return [.selectScenario(.offline), .clearCache, .remountList]
        case .cacheFirst, .forceRefresh:
            return [
                .selectScenario(.catalog), .restoreCatalogFile, .clearCache,
                .seedCacheFromCatalog, .bumpCatalogVersion, .clearEvents, .remountList
            ]
        case .staleFallback:
            return [
                .selectScenario(.catalog), .restoreCatalogFile, .clearCache, .seedCacheFromCatalog,
                .expireCache, .deleteCatalogFile, .clearEvents, .remountList
            ]
        case .clearedNoFallback:
            return [
                .selectScenario(.catalog), .restoreCatalogFile, .clearCache,
                .deleteCatalogFile, .clearEvents, .remountList
            ]
        case .cacheScope:
            return [
                .selectScenario(.catalog), .restoreCatalogFile, .clearCache, .seedCacheFromCatalog,
                .selectScenario(.rules), .clearCache, .clearEvents, .remountList
            ]
        case .configSwap:
            return [.selectScenario(.rules), .clearCache, .clearEvents]
        case .events, .overlay:
            return [
                .selectScenario(.catalog), .restoreCatalogFile, .clearCache,
                .seedCacheFromCatalog, .clearEvents, .remountList
            ]
        case .icons:
            return [.selectScenario(.remoteIcons), .clearCache, .clearEvents, .remountList]
        case .accessibility:
            return [.selectScenario(.catalog), .restoreCatalogFile, .clearCache, .clearEvents, .remountList]
        }
    }

    /// What the demo reports after the setup, and after the human has been to
    /// the list. Only facts it can actually read: its own `CacheManager`, the
    /// catalog file, and the events the package sent it.
    var observations: [DemoObservation] {
        switch self {
        case .selfExcluded, .promoRules, .configSwap:
            return [.expectedRows, .renderedRows]
        case .loading, .emptyCatalog, .unreachable, .accessibility:
            return [.cacheState]
        case .cacheFirst:
            return [.cacheVersusFile, .cacheUntouchedByLoad]
        case .forceRefresh:
            return [.cacheVersusFile, .cacheMatchesFile]
        case .staleFallback:
            return [.catalogFileState, .cacheKeptWhileStale]
        case .clearedNoFallback:
            return [.catalogFileState, .cacheDropped]
        case .cacheScope:
            return [.scopesIndependent]
        case .events:
            return [.expectedRows, .impressionsPerApp, .tapsRecorded]
        case .overlay:
            return [.tapsRecorded]
        case .icons:
            return [.expectedRows, .renderedRows]
        }
    }
}

/// One step of a case's setup.
///
/// Values rather than closures so a case stays a description of what it does;
/// ``DemoViewModel/run(_:)`` is the only thing that performs them.
enum DemoCaseAction: Equatable {
    /// Points the package at a scenario's catalog. Always the first step, since
    /// every cache operation below is scoped to the current catalog URL.
    case selectScenario(DemoScenario)
    /// Writes the editable catalog file back at its current version.
    case restoreCatalogFile
    /// Removes the catalog file, so fetches from the same URL start failing.
    case deleteCatalogFile
    /// Rewrites the catalog file one version higher.
    case bumpCatalogVersion
    /// Drops the cache for the current catalog URL.
    case clearCache
    /// Saves the current catalog file into the cache, exactly as a successful
    /// fetch would have. Gives the case a known cached version without needing
    /// a round trip through the list first.
    case seedCacheFromCatalog
    /// Backdates the cache to the expiry boundary, keeping the data.
    case expireCache
    /// Empties the event log so the next impressions are unambiguous.
    case clearEvents
    /// Gives the promo view a new identity, so its next load starts from
    /// nothing — the same reset a host app performs by leaving its settings
    /// screen and coming back. Deliberately absent from the config-swap case,
    /// which is about a view that stays put while its config changes.
    case remountList

    var label: LocalizedStringResource {
        switch self {
        case .selectScenario(let scenario):
            return "Select scenario: \(String(localized: scenario.displayName))"
        case .restoreCatalogFile: return "Write the catalog file back"
        case .deleteCatalogFile: return "Delete the catalog file"
        case .bumpCatalogVersion: return "Bump the catalog file to the next version"
        case .clearCache: return "Clear the cache for this catalog URL"
        case .seedCacheFromCatalog: return "Cache the catalog file, as a successful fetch would"
        case .expireCache: return "Expire the cache, keeping its data"
        case .clearEvents: return "Clear the event log"
        case .remountList: return "Rebuild the promo view, as reopening the screen would"
        }
    }
}
