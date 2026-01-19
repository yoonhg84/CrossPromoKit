# Implementation Plan: CrossPromoKit Demo App

**Branch**: `002-demo-app` | **Date**: 2026-01-19 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-demo-app/spec.md`

## Summary

Build a demonstration iOS app within the CrossPromoKit package that showcases the package's cross-promotion features. The app simulates "PhotoMagic" as the host app and displays promotional content for 4 other fictional apps using bundled JSON, SF Symbol icons, and supports English/Korean/Japanese localization.

## Technical Context

**Language/Version**: Swift 6 with `swiftLanguageModes: [.v6]`
**Primary Dependencies**: SwiftUI, StoreKit (SKOverlay), Foundation
**Storage**: UserDefaults (inherited from package cache), Bundle resources
**Testing**: XCTest (package tests), Manual testing for demo app
**Target Platform**: iOS 17.0+
**Project Type**: iOS App (Example project within Swift Package)
**Performance Goals**: App launch < 2s, UI state changes < 100ms
**Constraints**: Zero external dependencies, offline-capable, no API keys required
**Scale/Scope**: 5 fictional apps, 3 languages, 4 UI states

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| SwiftUI-First | ✅ Pass | All demo UI is SwiftUI |
| Swift 6 Strict Concurrency | ✅ Pass | Uses `swiftLanguageModes: [.v6]` |
| Minimal External Dependencies | ✅ Pass | Zero external dependencies |
| Offline-First | ✅ Pass | Bundled JSON, no network required |
| Privacy-Respecting Analytics | ✅ Pass | Demo logs to console only |
| Warm Embrace Design | ✅ Pass | Uses package's design tokens |

## Project Structure

### Documentation (this feature)

```text
specs/002-demo-app/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Technical decisions (R-001 to R-008)
├── data-model.md        # Entity definitions
├── quickstart.md        # Developer quickstart guide
├── contracts/
│   ├── demo-apps.json       # Mock data contract
│   └── demo-icon-colors.json # Icon color mapping
└── checklists/
    └── requirements.md      # Quality checklist
```

### Source Code (repository root)

```text
Example/
└── CrossPromoDemo/
    ├── CrossPromoDemo.xcodeproj
    └── CrossPromoDemo/
        ├── CrossPromoDemoApp.swift    # App entry point with @main
        ├── ContentView.swift          # Tab-based main view
        ├── SettingsView.swift         # MoreAppsView integration
        ├── DebugView.swift            # Debug tab (cache status, force refresh, language)
        ├── DebugOptionsView.swift     # State testing UI (loading/empty/error)
        ├── MockData/
        │   └── demo-apps.json         # Bundled mock data
        ├── Helpers/
        │   └── DemoEventHandler.swift # PromoEventDelegate implementation
        └── Resources/
            └── Localizable.xcstrings  # Localization (en, ko, ja)
```

**Structure Decision**: Separate Xcode project in `Example/` directory (R-001). This is the standard pattern for Swift Packages with example apps (Alamofire, Kingfisher, etc.) as SPM doesn't support executable targets with SwiftUI App lifecycle.

## Demo Data Specification

### Fictional Apps (5 apps)

| ID | Name | App Store ID | SF Symbol | Background Color | Category |
|----|------|--------------|-----------|------------------|----------|
| photomagic | PhotoMagic | 1234567890 | camera.filters | Purple (#AF52DE) | Photo & Video |
| weatherpal | WeatherPal | 1234567891 | cloud.sun.fill | Blue (#007AFF) | Weather |
| fittrack | FitTrack | 1234567892 | figure.run | Green (#34C759) | Health & Fitness |
| noteflow | NoteFlow | 1234567893 | note.text | Orange (#FF9500) | Productivity |
| budgetwise | BudgetWise | 1234567894 | dollarsign.circle.fill | Teal (#5AC8FA) | Finance |

### Localized Taglines

| App | English | Korean | Japanese |
|-----|---------|--------|----------|
| PhotoMagic | Transform your photos with AI magic | AI 마법으로 사진을 변환하세요 | AIマジックで写真を変換 |
| WeatherPal | Your friendly weather companion | 친근한 날씨 도우미 | あなたの天気パートナー |
| FitTrack | Track your fitness journey | 피트니스 여정을 추적하세요 | フィットネスの旅を追跡 |
| NoteFlow | Notes that flow with your thoughts | 생각과 함께 흐르는 노트 | 思考と共に流れるノート |
| BudgetWise | Smart budgeting made simple | 간단한 스마트 예산 관리 | シンプルなスマート予算管理 |

### JSON Structure

```json
{
  "apps": [
    {
      "id": "photomagic",
      "name": "PhotoMagic",
      "appStoreID": "1234567890",
      "iconURL": "sf-symbol://camera.filters",
      "category": "Photo & Video",
      "tagline": {
        "en": "Transform your photos with AI magic",
        "ko": "AI 마법으로 사진을 변환하세요",
        "ja": "AIマジックで写真を変換"
      }
    }
    // ... 4 more apps
  ],
  "promoRules": null
}
```

**Note**: `iconURL` uses `sf-symbol://` scheme to indicate SF Symbol usage instead of remote URL.

## Demo App Features

### Tab 1: Settings Tab
- **MoreAppsView Integration**: Embedded `MoreAppsView` from CrossPromoKit
- **Current App ID**: "photomagic" (excluded from list)
- **Event Logging**: Console output for impression/tap events
- **SKOverlay**: Real overlay on device, fallback alert on simulator

### Tab 2: Debug Tab
- **Cache Status**: Display current cache state (valid/expired/empty)
- **Force Refresh Button**: Clear cache and reload data
- **Language Switcher**: Quick language change for testing (en/ko/ja)
- **State Testing**: Picker to force loading/empty/error states

## Key Decisions Reference

| Decision | Choice | Reference |
|----------|--------|-----------|
| Example app structure | Separate Xcode project in `Example/` | R-001 |
| Mock data strategy | Bundled JSON via `Bundle.main` | R-002 |
| Simulator handling | Fallback alert explaining limitation | R-003 |
| State testing | Debug menu with picker | R-004 |
| App icons | SF Symbols with colored backgrounds | R-005 |
| Event delegation | Console logging | R-006 |
| Localization testing | Xcode scheme language override | R-007 |
| Package integration | Local package via "Add Local..." | R-008 |

## Next Steps

Run `/speckit.tasks` to generate the task breakdown for implementation.
