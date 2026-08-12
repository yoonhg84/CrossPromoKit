# CrossPromoKit Development Guidelines

## Overview

Swift package (SPM) providing a drop-in SwiftUI `MoreAppsView` for cross-promoting
your other iOS apps from a remote JSON catalog, with SKOverlay-based App Store
presentation.

- Swift 6.0 tools, strict concurrency (Swift 6 language mode), iOS 17+ only
- Frameworks: SwiftUI, StoreKit (SKOverlay), Foundation (URLSession, UserDefaults)
- No third-party dependencies

## Project Structure

```text
Sources/CrossPromoKit/
  Models/        PromoApp, AppCatalog, PromoConfig, PromoEvent, LocalizedText
  Services/      PromoService, NetworkClient, CacheManager
  Views/         MoreAppsView, PromoAppRow, EmptyStateView, Components/AsyncAppIcon
  Protocols/     PromoEventDelegate
  Extensions/    L10n, Locale+Supported
  Design/        WarmEmbraceTokens (colors, spacing, typography)
  Resources/     Localizable.xcstrings (en, ko, ja)
Tests/CrossPromoKitTests/      swift-testing suites + StubURLProtocol/TestFixtures
Example/CrossPromoDemo/        demo app (CrossPromoDemo.xcodeproj, consumes the local package)
docs/images/                   README assets
specs/                         historical requirement docs (FR-### references in code point here)
```

## Commands

`swift build` / `swift test` do **not** work: the package is iOS-only and the
SwiftUI/StoreKit code fails to compile for the macOS host. Use xcodebuild against
a simulator instead.

```bash
# Run the package tests
xcodebuild test -scheme CrossPromoKit -destination 'platform=iOS Simulator,name=iPhone 17'

# Run the demo app (from Example/CrossPromoDemo)
xcodebuild -scheme CrossPromoDemo -destination 'platform=iOS Simulator,name=iPhone 17' build
```

```bash
# Lint (config: .swiftlint.yml, covers Sources only)
# Use the version pinned in .swiftlint-version — CI downloads that exact release.
swiftlint version   # must match `cat .swiftlint-version`
swiftlint lint --strict
```

CI runs the same `--strict` invocation with the pinned version, so any warning
fails the build. To upgrade: bump `.swiftlint-version` (and your local install to
the same version), run `swiftlint lint --strict` to surface violations added by
the new release's rules, fix them in the same PR.

## Code Style

- Public API must be explicitly `public`; keep types `Sendable`.
- Concurrency: `PromoService` and `PromoEventDelegate` are `@MainActor`;
  `NetworkClient` and `CacheManager` are actors. Do not reach for
  `@unchecked Sendable` to silence warnings.
- User-facing strings go through `L10n` / `Localizable.xcstrings`, never literals.
- Colors, spacing, and fonts come from `WarmEmbraceTokens`, never hardcoded.
- `.swiftlint.yml` opt-ins ban `force_unwrapping` and implicitly unwrapped
  optionals; `line_length` and `trailing_whitespace` are disabled.
- Tests use swift-testing (`import Testing`, `@Test`/`@Suite`), not XCTest.
- UI is SwiftUI-only; observable state uses the `@Observable` macro, never
  `ObservableObject`/`@Published`.
- Offline-first: a failed fetch falls back to cache and degrades silently — never
  block rendering or surface an error dialog for a network failure.
- Keep the package dependency-free; use system frameworks. Adding a runtime
  dependency needs an explicit justification in the PR.
- Public types and methods carry doc comments; public API changes update the README.
