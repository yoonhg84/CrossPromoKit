# Research: CrossPromoKit Demo App

**Feature Branch**: `002-demo-app`
**Date**: 2026-01-19
**Status**: Complete

## Overview

This research document captures technical decisions and best practices for implementing the CrossPromoKit Demo App, which serves as an example application demonstrating the package's capabilities.

---

## R-001: Swift Package Example App Structure

**Question**: How should the Example app be structured within a Swift Package?

**Decision**: Create a separate Xcode project in an `Example/` directory at the package root.

**Rationale**:
- Swift Package Manager doesn't support executable targets with SwiftUI App lifecycle
- Separate Xcode project allows full iOS app capabilities (Info.plist, assets, entitlements)
- Package dependencies can reference the local package via relative path
- This is the standard pattern used by major packages (Alamofire, Kingfisher, etc.)

**Alternatives Considered**:
1. **Executable target in Package.swift**: Rejected - doesn't support `@main` App struct
2. **Workspace with Package**: More complex setup, harder for developers to run quickly

**Implementation**:
```
Example/
└── CrossPromoDemo/
    ├── CrossPromoDemo.xcodeproj
    └── CrossPromoDemo/
        ├── CrossPromoDemoApp.swift
        ├── ContentView.swift
        └── ...
```

---

## R-002: Local Mock Data Strategy

**Question**: How should demo data be provided without network dependency?

**Decision**: Bundle a `demo-apps.json` file in the Example app's resources and load via `Bundle.main`.

**Rationale**:
- Ensures the demo works offline and without any server setup
- Developers can immediately run and see results
- Matches the reliability requirement (FR-010, FR-012)
- Easy to modify for testing different scenarios

**Alternatives Considered**:
1. **Hardcoded Swift data**: Less flexible, harder to visualize data structure
2. **Remote mock server**: Adds setup complexity, network dependency

**Implementation**:
```swift
// Load from bundle
guard let url = Bundle.main.url(forResource: "demo-apps", withExtension: "json"),
      let data = try? Data(contentsOf: url) else { return }
```

---

## R-003: SKOverlay Simulator Handling

**Question**: How should the app handle SKOverlay on simulator where it's unavailable?

**Decision**: Detect simulator environment and show a fallback alert explaining the limitation.

**Rationale**:
- SKOverlay requires actual App Store and device entitlements
- Crashing or showing cryptic errors provides poor developer experience
- Clear messaging helps developers understand it works on real devices

**Alternatives Considered**:
1. **Silent no-op**: Confusing - developer doesn't know if tap worked
2. **Mock overlay UI**: Over-engineering for a demo app

**Implementation**:
```swift
#if targetEnvironment(simulator)
    // Show alert explaining SKOverlay unavailable
#else
    // Present actual SKOverlay
#endif
```

---

## R-004: UI State Testing Approach

**Question**: How to enable testing of different UI states (loading, empty, error)?

**Decision**: Use a debug menu / settings toggle in the Example app to force different states.

**Rationale**:
- Easy to switch between states for screenshot capture
- Doesn't require code changes or recompilation
- Natural fit in a demo/example context

**Alternatives Considered**:
1. **Launch arguments**: More hidden, less discoverable
2. **Separate targets per state**: Too much overhead

**Implementation**:
```swift
enum DemoState: String, CaseIterable {
    case normal, loading, empty, error
}

@State private var selectedState: DemoState = .normal
```

---

## R-005: Fictional App Icons

**Question**: What should be used for fictional app icons?

**Decision**: Use SF Symbols as placeholder icons with colored backgrounds.

**Rationale**:
- No copyright issues with fictional app icons
- SF Symbols are built into iOS - no additional assets needed
- Can create visually appealing icons with symbol + background color
- Matches the "no external dependencies" constraint

**Alternatives Considered**:
1. **Custom designed icons**: Requires design work, overkill for demo
2. **Placeholder images**: Less visually interesting
3. **Real App Store icons**: Copyright issues, external URLs

**Implementation**:
```swift
// Demo icon using SF Symbol with colored background
struct DemoAppIcon: View {
    let symbolName: String
    let backgroundColor: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
            Image(systemName: symbolName)
                .font(.title)
                .foregroundColor(.white)
        }
    }
}
```

**Demo App Icons**:
| App | SF Symbol | Color |
|-----|-----------|-------|
| PhotoMagic | `camera.filters` | Purple |
| WeatherPal | `cloud.sun.fill` | Blue |
| FitTrack | `figure.run` | Green |
| NoteFlow | `note.text` | Orange |
| BudgetWise | `dollarsign.circle.fill` | Teal |

---

## R-006: PromoEventDelegate Demonstration

**Question**: How to demonstrate the event delegate in the Example app?

**Decision**: Log events to console with clear formatting and optionally show in-app toast.

**Rationale**:
- Console logs are visible in Xcode, easy for developers to verify
- Optional toast provides immediate visual feedback
- Demonstrates the integration pattern without complex analytics setup

**Implementation**:
```swift
class DemoEventHandler: PromoEventDelegate {
    func promoService(_ service: PromoService, didEmit event: PromoEvent) {
        switch event {
        case .impression(let appID):
            print("📊 [Demo] Impression: \(appID)")
        case .tap(let appID):
            print("👆 [Demo] Tap: \(appID)")
        }
    }
}
```

---

## R-007: Localization Testing

**Question**: How to easily test different languages in the Example app?

**Decision**: Use Xcode scheme settings to override app language, document in README.

**Rationale**:
- Standard Xcode approach - no custom implementation needed
- Works consistently across simulator and device
- Developers are familiar with this pattern

**Documentation**:
```
To test localization:
1. Edit scheme → Run → Options → App Language
2. Select Korean, Japanese, or English
3. Run the app
```

---

## R-008: Package Integration Point

**Question**: How should the Example app reference the local CrossPromoKit package?

**Decision**: Add local package dependency via Xcode's "Add Local..." option.

**Rationale**:
- Automatically tracks changes to the package during development
- No need to publish or version the package for testing
- Standard Xcode workflow

**Implementation**:
1. In Xcode project, File → Add Package Dependencies
2. Select "Add Local..."
3. Navigate to CrossPromoKit root directory
4. Select CrossPromoKit package

---

## Constitution Compliance Check

| Principle | Status | Notes |
|-----------|--------|-------|
| SwiftUI-First | ✅ Pass | All demo UI is SwiftUI |
| Swift 6 Strict Concurrency | ✅ Pass | Example app inherits package settings |
| Minimal External Dependencies | ✅ Pass | Zero external dependencies |
| Offline-First | ✅ Pass | Bundled JSON, no network required |
| Privacy-Respecting Analytics | ✅ Pass | Demo logs to console only |
| Warm Embrace Design | ✅ Pass | Uses package's design tokens |

---

## Summary

All technical questions resolved. The Example app will:
- Live in `Example/CrossPromoDemo/` as a separate Xcode project
- Use bundled JSON for demo data
- Use SF Symbols for fictional app icons
- Handle simulator limitations gracefully
- Provide state testing via debug menu
- Demonstrate event delegation via console logging
