# CrossPromoKit

Swift package: a drop-in SwiftUI `MoreAppsView` that cross-promotes your other iOS
apps from a remote JSON catalog, opening the App Store via SKOverlay.

Swift 6 strict concurrency, iOS 17+, no third-party dependencies.

## Commands

`swift build` / `swift test` **fail** — the package is iOS-only and its SwiftUI /
StoreKit code cannot compile for the macOS host. Always use a simulator:

```bash
xcodebuild test -scheme CrossPromoKit -destination 'platform=iOS Simulator,name=iPhone 17'
swiftlint lint --strict   # version must match .swiftlint-version; CI fails on any warning
```

Touching `Example/`? Build the demo too — it is what proves isolation and SwiftUI
overload resolution:

```bash
xcodebuild build -project Example/CrossPromoDemo/CrossPromoDemo.xcodeproj \
  -scheme CrossPromoDemo -destination 'platform=iOS Simulator,name=iPhone 17' \
  CODE_SIGNING_ALLOWED=NO
```

## Principles

**Concurrency.** `PromoService` and `PromoEventDelegate` are `@MainActor`;
`NetworkClient` and `CacheManager` are actors. Never silence a warning with
`@unchecked Sendable` — fix the isolation.

**Offline-first.** A failed fetch falls back to cache, even stale cache. Never
block rendering or raise a dialog because the network failed.

**No hardcoded surfaces.** User-facing strings go through `L10n` /
`Localizable.xcstrings` (en/ko/ja). Colors, spacing, and fonts come from
`WarmEmbraceTokens`.

**No new dependencies.** System frameworks only; adding one needs justification
in the PR.

**SwiftUI + `@Observable`.** Never `ObservableObject` / `@Published`.

**Tests are Swift Testing** (`@Test` / `@Suite`), never XCTest. Never assert on
wall-clock durations. If a test passes against deliberately broken code, it is
not a test.

**Public API is documented API.** Public types and methods carry doc comments,
and a public change updates both READMEs together.

## Workflow

Issue → branch → PR → green CI → merge. `/ship` runs that pipeline end to end;
`.claude/agents/issue-worker.md` is the per-issue contract.

`specs/` is a historical record, not a spec to follow — parts of it describe APIs
that no longer exist. Code cites it only via `FR-###`.
