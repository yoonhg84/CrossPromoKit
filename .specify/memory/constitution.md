<!--
Sync Impact Report
==================
Version change: N/A → 1.0.0 (Initial)
Modified principles: None (initial creation)
Added sections:
  - Core Principles (6 principles)
  - Technical Stack
  - Development Workflow
  - Governance
Removed sections: None
Templates requiring updates:
  - .specify/templates/plan-template.md: ✅ Compatible (no changes needed)
  - .specify/templates/spec-template.md: ✅ Compatible (no changes needed)
  - .specify/templates/tasks-template.md: ✅ Compatible (no changes needed)
Follow-up TODOs: None
-->

# CrossPromoKit Constitution

## Core Principles

### I. SwiftUI-First

CrossPromoKit MUST be built entirely with SwiftUI using modern declarative patterns.

**Requirements:**
- All UI components MUST use SwiftUI views exclusively; UIKit is prohibited except for system integrations that lack SwiftUI equivalents
- Views MUST follow the single-responsibility principle: one view, one purpose
- State management MUST use `@Observable` macro (iOS 17+) over legacy `ObservableObject`
- View models MUST be marked with `@Observable` and MUST NOT use `@Published` properties
- Environment values MUST be preferred over dependency injection for cross-cutting concerns
- ViewModifiers MUST be used for reusable styling; avoid inline style repetition
- Preview providers MUST exist for all public views with representative sample data

**Rationale:** SwiftUI-first ensures consistency, leverages Apple's latest optimizations, and provides a unified codebase that is easier to maintain and test.

### II. Swift 6 Strict Concurrency

All code MUST compile with Swift 6 strict concurrency checking enabled without warnings.

**Requirements:**
- `SWIFT_STRICT_CONCURRENCY = complete` MUST be set in build settings
- All types crossing isolation boundaries MUST conform to `Sendable`
- Mutable shared state MUST be protected by actors; global mutable state is prohibited
- `@MainActor` MUST be applied to all UI-related types and their dependencies
- `nonisolated` MUST be explicitly specified when crossing actor boundaries intentionally
- Async/await MUST be used for all asynchronous operations; completion handlers are prohibited
- Task cancellation MUST be handled explicitly in long-running operations

**Rationale:** Strict concurrency eliminates data races at compile time, ensuring thread safety and preventing hard-to-debug runtime crashes.

### III. Minimal External Dependencies

The package MUST minimize external dependencies to reduce attack surface and maintenance burden.

**Requirements:**
- External dependencies MUST be justified in writing before addition
- System frameworks (Foundation, SwiftUI, Combine) MUST be preferred over third-party alternatives
- If a dependency is required, it MUST: (a) be actively maintained, (b) have Swift 6 support, (c) be Sendable-compliant
- Image loading, networking, and persistence MUST use system APIs (URLSession, SwiftData/UserDefaults)
- Build tools and test-only dependencies are exempt from this rule
- Dependency count for runtime SHOULD NOT exceed 3 packages

**Rationale:** Fewer dependencies mean fewer breaking changes, smaller binary size, faster builds, and reduced security vulnerabilities.

### IV. Offline-First Architecture

The package MUST function fully offline with graceful degradation for network-dependent features.

**Requirements:**
- All promotional content MUST be bundled or cached locally for offline access
- Network requests MUST be non-blocking and MUST NOT prevent UI rendering
- Failed network requests MUST degrade gracefully without error dialogs or crashes
- Cached data MUST have explicit expiration policies (default: 7 days)
- Background refresh MUST use BGTaskScheduler with appropriate QoS
- Retry logic MUST use exponential backoff with jitter (max 3 retries)

**Rationale:** Users may have intermittent connectivity; offline-first ensures the app remains useful and responsive regardless of network conditions.

### V. Privacy-Respecting Analytics

All analytics MUST respect user privacy and comply with Apple's App Tracking Transparency guidelines.

**Requirements:**
- Analytics MUST NOT collect personally identifiable information (PII)
- Device identifiers (IDFA, IDFV) MUST NOT be used without explicit ATT consent
- Analytics events MUST be aggregated and anonymized before transmission
- Users MUST be able to opt-out of analytics entirely via a public API
- Analytics MUST be disabled by default; opt-in is required
- All analytics data MUST be transmitted over HTTPS with certificate pinning
- Analytics payload size MUST NOT exceed 1KB per event batch

**Rationale:** Privacy is a fundamental user right; respecting it builds trust and ensures App Store compliance.

### VI. Warm Embrace Design System

All visual elements MUST adhere to the "Warm Embrace" design language for consistency.

**Requirements:**
- Primary accent color MUST be Warm Coral: `#FF6B5B` (light) / `#FF8577` (dark)
- Secondary accent color MUST be Soft Teal: `#5BBFBA` (light) / `#7DD4CF` (dark)
- Background colors MUST use warm neutrals: `#FFF8F6` (light) / `#1C1917` (dark)
- Typography MUST use SF Pro with rounded variants for headings
- Corner radius MUST be 12pt for cards, 8pt for buttons, 16pt for sheets
- Animations MUST use spring timing with `duration: 0.3, bounce: 0.2`
- All colors MUST meet WCAG 2.1 AA contrast requirements (4.5:1 minimum)
- Dark mode MUST be supported via `@Environment(\.colorScheme)`

**Rationale:** A consistent design language creates a cohesive user experience and strengthens brand identity across all FinePocket apps.

## Technical Stack

**Platform Requirements:**
- iOS 17.0+ minimum deployment target
- Swift 6.0 with strict concurrency
- Xcode 16.0+ for development

**Approved System Frameworks:**
- SwiftUI (UI layer)
- Foundation (core utilities)
- Combine (reactive bindings where needed for system APIs)
- SwiftData (persistence, if needed)
- BackgroundTasks (background refresh)
- StoreKit 2 (if in-app features needed)

**Testing Stack:**
- XCTest for unit and integration tests
- Swift Testing framework (`@Test` macro) preferred for new tests
- ViewInspector or similar for SwiftUI view testing (optional)

**Build Configuration:**
- SPM (Swift Package Manager) exclusively; CocoaPods/Carthage prohibited
- All warnings treated as errors in CI
- Code coverage minimum: 80% for public API

## Development Workflow

**Branch Strategy:**
- `main`: production-ready, protected
- `feature/*`: all new work
- `fix/*`: bug fixes
- `release/*`: release preparation

**Code Review Requirements:**
- All PRs MUST pass CI checks before merge
- All PRs MUST have at least one approving review
- All public API changes MUST include documentation updates
- Breaking changes MUST be documented in CHANGELOG.md

**Quality Gates:**
- SwiftLint MUST pass with zero violations
- All tests MUST pass
- Build MUST succeed with zero warnings
- Strict concurrency checking MUST pass

**Documentation Standards:**
- All public types and methods MUST have documentation comments
- README MUST include integration guide and example usage
- CHANGELOG MUST follow Keep a Changelog format

## Governance

This constitution is the authoritative source for CrossPromoKit development standards. All code contributions, reviews, and architectural decisions MUST comply with these principles.

**Amendment Process:**
1. Propose changes via GitHub Issue with `constitution` label
2. Discussion period: minimum 3 days
3. Approval: maintainer consensus required
4. Implementation: update constitution, bump version, update dependent templates
5. Migration: existing code MUST be brought into compliance within 2 releases

**Compliance Verification:**
- CI pipelines MUST enforce technical requirements automatically
- Code reviews MUST verify principle adherence
- Quarterly audits SHOULD assess overall compliance

**Versioning Policy:**
- MAJOR: Principle removal or fundamental redefinition
- MINOR: New principle added or existing principle materially expanded
- PATCH: Clarifications, typo fixes, non-semantic changes

**Version**: 1.0.0 | **Ratified**: 2026-01-19 | **Last Amended**: 2026-01-19
