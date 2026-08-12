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
specs/                         spec-kit feature specs (001-cross-promo-kit, 002-demo-app)
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

Lint config lives in `.swiftlint.yml` (covers `Sources` only, `Tests` excluded).
SwiftLint is not necessarily installed locally; if available, run `swiftlint` from
the repo root.

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

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
