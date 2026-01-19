# Quickstart Guide: CrossPromoKit

**Branch**: `001-cross-promo-kit` | **Date**: 2026-01-19

## Overview

CrossPromoKit enables cross-promotion of FinePocket apps within the app portfolio. This guide shows how to integrate the package into any FinePocket iOS app.

---

## Installation

### Swift Package Manager

Add CrossPromoKit to your `Package.swift` or via Xcode:

```swift
dependencies: [
    .package(url: "https://github.com/user/CrossPromoKit.git", from: "1.0.0")
]
```

Or in Xcode: **File → Add Package Dependencies** → Enter repository URL.

---

## Basic Usage

### 1. Import the Package

```swift
import CrossPromoKit
```

### 2. Add to Settings Screen

The simplest integration is adding `MoreAppsView` to your settings:

```swift
import SwiftUI
import CrossPromoKit

struct SettingsView: View {
    var body: some View {
        List {
            // Your existing settings sections...

            Section("More from FinePocket") {
                MoreAppsView(currentAppID: "finebill")
            }
        }
    }
}
```

Replace `"finebill"` with your app's identifier from the catalog.

---

## Configuration Options

### Custom JSON Endpoint

By default, CrossPromoKit fetches from the FinePocket GitHub repository. To use a custom endpoint:

```swift
let config = PromoConfig(
    jsonURL: URL(string: "https://your-domain.com/promo-catalog.json")!,
    currentAppID: "finebill"
)

MoreAppsView(config: config)
```

### Analytics Events

To receive analytics events (impressions and taps), implement the delegate:

```swift
class MyAnalyticsHandler: PromoEventDelegate {
    @MainActor
    func promoService(_ service: PromoService, didEmit event: PromoEvent) {
        switch event {
        case .impression(let appID):
            Analytics.log("promo_impression", parameters: ["app_id": appID])
        case .tap(let appID):
            Analytics.log("promo_tap", parameters: ["app_id": appID])
        }
    }
}

// In your view
struct SettingsView: View {
    @State private var analyticsHandler = MyAnalyticsHandler()

    var body: some View {
        MoreAppsView(
            currentAppID: "finebill",
            eventDelegate: analyticsHandler
        )
    }
}
```

---

## App Identifiers

Use these identifiers for `currentAppID`:

| App | Identifier |
|-----|------------|
| FineBill | `finebill` |
| Bookary | `bookary` |
| FinePomo | `finepomo` |
| Stedio | `stedio` |
| Littory | `littory` |

---

## JSON Catalog Format

The remote JSON must follow this structure:

```json
{
  "apps": [
    {
      "id": "finebill",
      "name": "FineBill",
      "appStoreID": "1234567891",
      "iconURL": "https://example.com/icons/finebill.png",
      "category": "생산성",
      "tagline": {
        "en": "Track your bills effortlessly",
        "ko": "손쉬운 청구서 관리",
        "ja": "請求書を簡単に追跡"
      }
    }
  ],
  "promoRules": {
    "finebill": ["bookary", "finepomo", "littory"]
  }
}
```

### Fields

- **apps**: Array of promotable apps (required)
- **promoRules**: Maps host app ID → allowed promo app IDs (optional)
  - If omitted, all apps are shown (minus current app)

---

## Localization

CrossPromoKit supports three languages:
- **English** (en) - Required fallback
- **Korean** (ko) - Optional
- **Japanese** (ja) - Optional

The tagline automatically displays in the device's current language, falling back to English if unavailable.

---

## Offline Support

CrossPromoKit caches data for 24 hours:
- **Fresh data**: Fetched from network when cache is expired or empty
- **Cached data**: Used when network is unavailable or within cache validity
- **Empty state**: Shows retry option when both network and cache fail

No additional configuration needed—offline support works automatically.

---

## Requirements

- iOS 17.0+
- Swift 6.0+
- Xcode 16.0+

---

## Troubleshooting

### Apps not showing

1. Verify `currentAppID` matches an ID in the JSON catalog
2. Check network connectivity
3. Verify JSON endpoint returns valid data

### SKOverlay not appearing

1. Ensure app is running on a real device (not simulator)
2. Verify `appStoreID` in JSON is correct
3. Check that StoreKit framework is linked

### Cache issues

To force a fresh fetch during development:
```swift
UserDefaults.standard.removeObject(forKey: "CrossPromoKit.catalog")
UserDefaults.standard.removeObject(forKey: "CrossPromoKit.timestamp")
```

---

## Next Steps

- See [Data Model](./data-model.md) for entity details
- See [JSON Schema](./contracts/catalog-schema.json) for validation
- See [Research](./research.md) for technical decisions
