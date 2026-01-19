# Research: CrossPromoKit

**Date**: 2026-01-19
**Branch**: `001-cross-promo-kit`

## Research Summary

All technical decisions have been resolved. No NEEDS CLARIFICATION items remained from the Technical Context phase. This document captures key architectural decisions and best practices research.

---

## 1. SKOverlay Implementation

### Decision
Use `SKOverlay` with `SKOverlay.Configuration.appClip(position:)` replaced by `SKOverlay.Configuration.app(position:)` for full app promotion.

### Rationale
- SKOverlay is the recommended Apple API for in-app App Store promotion
- Provides native UI that matches App Store design
- Handles all download/open logic automatically
- Available on iOS 14+ (compatible with our iOS 17+ target)

### Alternatives Considered
| Alternative | Why Rejected |
|-------------|--------------|
| StoreKit Product View | Requires product ID, not App Store ID; more complex setup |
| Open App Store URL | Leaves the app; poor UX |
| Custom webview | Maintenance burden; inconsistent UX |

### Implementation Notes
```swift
// SKOverlay requires UIWindowScene
let config = SKOverlay.AppConfiguration(appIdentifier: appStoreID, position: .bottom)
let overlay = SKOverlay(configuration: config)
overlay.present(in: windowScene)
```

---

## 2. Swift 6 Sendable Conformance Strategy

### Decision
All model types will be `struct` with `Sendable` conformance. Service layer uses `@MainActor` isolation.

### Rationale
- Structs are implicitly Sendable when all stored properties are Sendable
- String, Int, URL are already Sendable
- @MainActor on service prevents data races in UI updates

### Implementation Pattern
```swift
// Models: Sendable structs
struct PromoApp: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let appStoreID: String
    // ...
}

// Service: MainActor isolated
@MainActor
@Observable
final class PromoService {
    private(set) var apps: [PromoApp] = []
    // ...
}
```

### Alternatives Considered
| Alternative | Why Rejected |
|-------------|--------------|
| Actor for service | Unnecessary complexity; MainActor sufficient for UI-bound service |
| @unchecked Sendable | Unsafe; violates Constitution II |

---

## 3. UserDefaults Caching Strategy

### Decision
Store serialized JSON blob in UserDefaults with separate timestamp key for expiration tracking.

### Rationale
- Simple, synchronous API suitable for small JSON payloads
- No additional framework dependencies
- Persists across app launches automatically
- Sufficient for ~5-10KB of app catalog data

### Implementation Pattern
```swift
private enum CacheKeys {
    static let catalog = "CrossPromoKit.catalog"
    static let timestamp = "CrossPromoKit.timestamp"
}

func save(_ catalog: AppCatalog) {
    let data = try? JSONEncoder().encode(catalog)
    UserDefaults.standard.set(data, forKey: CacheKeys.catalog)
    UserDefaults.standard.set(Date(), forKey: CacheKeys.timestamp)
}

func load() -> AppCatalog? {
    guard let timestamp = UserDefaults.standard.object(forKey: CacheKeys.timestamp) as? Date,
          Date().timeIntervalSince(timestamp) < 86400 else { // 24 hours
        return nil
    }
    guard let data = UserDefaults.standard.data(forKey: CacheKeys.catalog) else {
        return nil
    }
    return try? JSONDecoder().decode(AppCatalog.self, from: data)
}
```

### Alternatives Considered
| Alternative | Why Rejected |
|-------------|--------------|
| SwiftData | Overkill for simple key-value; adds complexity |
| FileManager + JSON file | More code; no significant benefit |
| URLCache | Less control over expiration policy |

---

## 4. @Observable vs ObservableObject

### Decision
Use `@Observable` macro (iOS 17+) exclusively.

### Rationale
- Constitution I mandates @Observable over legacy ObservableObject
- Simpler syntax: no @Published wrappers needed
- Better performance: fine-grained observation
- Native Swift macro, not Combine dependency

### Implementation Pattern
```swift
@MainActor
@Observable
final class PromoService {
    private(set) var apps: [PromoApp] = []
    private(set) var isLoading = false
    private(set) var error: Error?

    func loadApps() async {
        isLoading = true
        defer { isLoading = false }
        // ...
    }
}

// In View
struct MoreAppsView: View {
    @State private var service = PromoService()

    var body: some View {
        // Automatic observation
    }
}
```

---

## 5. Localization Fallback Strategy

### Decision
Use dictionary-based `LocalizedText` with runtime language detection and English fallback.

### Rationale
- Server provides all translations in JSON; no need for .strings files for dynamic content
- English is guaranteed fallback per FR-005
- Runtime detection via `Locale.current.language.languageCode`

### Implementation Pattern
```swift
struct LocalizedText: Codable, Sendable {
    let en: String
    let ko: String?
    let ja: String?

    var localized: String {
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        switch code {
        case "ko": return ko ?? en
        case "ja": return ja ?? en
        default: return en
        }
    }
}
```

---

## 6. Error Handling & Graceful Degradation

### Decision
Three-tier fallback: Network → Cache → Empty State with retry option.

### Rationale
- Constitution IV mandates offline-first with graceful degradation
- Users should never see raw error messages
- Always provide an action path (retry or acknowledge)

### Implementation Pattern
```swift
enum LoadState {
    case idle
    case loading
    case loaded([PromoApp])
    case empty(canRetry: Bool)
}

func loadApps() async {
    // 1. Try network
    if let catalog = await fetchFromNetwork() {
        cache.save(catalog)
        state = .loaded(filter(catalog.apps))
        return
    }

    // 2. Fall back to cache
    if let cached = cache.load() {
        state = .loaded(filter(cached.apps))
        return
    }

    // 3. Empty state with retry
    state = .empty(canRetry: true)
}
```

---

## 7. Delegate Pattern for Analytics Events

### Decision
Protocol-based delegate with weak reference, async-friendly design.

### Rationale
- Constitution V prohibits direct analytics collection
- Host app decides how to handle events
- Weak reference prevents retain cycles

### Implementation Pattern
```swift
public enum PromoEvent: Sendable {
    case impression(appID: String)
    case tap(appID: String)
}

public protocol PromoEventDelegate: AnyObject, Sendable {
    func promoService(_ service: PromoService, didEmit event: PromoEvent)
}

@MainActor
@Observable
public final class PromoService {
    public weak var eventDelegate: PromoEventDelegate?

    private func emit(_ event: PromoEvent) {
        eventDelegate?.promoService(self, didEmit: event)
    }
}
```

---

## Conclusion

All technical decisions are finalized. No outstanding clarifications required. Ready for Phase 1: Data Model and Contracts.
