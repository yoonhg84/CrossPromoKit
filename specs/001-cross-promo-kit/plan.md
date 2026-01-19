# Implementation Plan: CrossPromoKit

**Branch**: `001-cross-promo-kit` | **Date**: 2026-01-19 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-cross-promo-kit/spec.md`

## Summary

CrossPromoKit is a Swift Package that enables cross-promotion of FinePocket apps within the app portfolio. The package fetches app data from a remote JSON endpoint, caches it locally for 24 hours, and presents a SwiftUI-based UI with localized content and in-app App Store overlay via SKOverlay. All data models conform to Sendable for Swift 6 strict concurrency, and analytics events are delegated to host apps via a protocol-based callback mechanism.

## Technical Context

**Language/Version**: Swift 6.0 with strict concurrency checking (`SWIFT_STRICT_CONCURRENCY = complete`)
**Primary Dependencies**: SwiftUI, StoreKit (SKOverlay), Foundation (URLSession, UserDefaults)
**Storage**: UserDefaults for JSON cache with timestamp-based 24-hour expiration
**Testing**: Swift Testing framework (`@Test` macro), XCTest for integration tests
**Target Platform**: iOS 17.0+
**Project Type**: Swift Package (library)
**Performance Goals**: <1s for cached data display, <2s for fresh network fetch
**Constraints**: Offline-capable, no external dependencies, Sendable-compliant models
**Scale/Scope**: 5 target apps, 3 supported languages (ko, en, ja)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| I. SwiftUI-First | ✅ PASS | SwiftUI only, @Observable macro, no UIKit |
| II. Swift 6 Strict Concurrency | ✅ PASS | All models Sendable, @MainActor for UI types, async/await |
| III. Minimal External Dependencies | ✅ PASS | Zero external dependencies, system frameworks only |
| IV. Offline-First Architecture | ✅ PASS | 24-hour cache, graceful degradation, non-blocking network |
| V. Privacy-Respecting Analytics | ✅ PASS | No direct analytics, delegate to host app |
| VI. Warm Embrace Design System | ✅ PASS | Will implement design tokens in Views |

**Gate Result**: ✅ ALL PASSED - Proceed to Phase 0

## Project Structure

### Documentation (this feature)

```text
specs/001-cross-promo-kit/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (JSON schema)
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
Sources/CrossPromoKit/
├── Models/
│   ├── PromoApp.swift           # App entity (Sendable)
│   ├── PromoConfig.swift        # Configuration with JSON URL
│   ├── LocalizedText.swift      # Localized tagline (Sendable)
│   ├── AppCatalog.swift         # Root JSON model (Sendable)
│   └── PromoEvent.swift         # Analytics event types
├── Services/
│   ├── PromoService.swift       # @Observable, @MainActor service
│   ├── CacheManager.swift       # UserDefaults cache with expiration
│   └── NetworkClient.swift      # URLSession wrapper (async/await)
├── Views/
│   ├── MoreAppsView.swift       # Main container view
│   ├── PromoAppRow.swift        # Individual app row
│   ├── EmptyStateView.swift     # Empty/error state
│   └── Components/
│       └── AsyncAppIcon.swift   # Async image loading with placeholder
├── Design/
│   └── WarmEmbraceTokens.swift  # Design system colors, spacing, animations
├── Protocols/
│   └── PromoEventDelegate.swift # Delegate for analytics events
└── Extensions/
    └── Locale+Supported.swift   # Language detection helper

Tests/CrossPromoKitTests/
├── Models/
│   └── PromoAppTests.swift
├── Services/
│   ├── PromoServiceTests.swift
│   └── CacheManagerTests.swift
└── Views/
    └── MoreAppsViewTests.swift
```

**Structure Decision**: Swift Package structure with Sources/ and Tests/ at root. Models, Services, Views separation follows MVVM-lite pattern with @Observable service layer.

## Complexity Tracking

> No violations detected. All design choices align with Constitution principles.

| Aspect | Choice | Rationale |
|--------|--------|-----------|
| State Management | @Observable (not ObservableObject) | Constitution I: SwiftUI-First requires iOS 17+ patterns |
| Caching | UserDefaults (not SwiftData) | Simple key-value storage sufficient for JSON blob |
| Analytics | Delegate pattern (not direct collection) | Constitution V: Privacy-respecting, host app controls |
