# Data Model: CrossPromoKit

**Date**: 2026-01-19
**Branch**: `001-cross-promo-kit`

## Entity Overview

```
┌─────────────────┐
│   AppCatalog    │ (Root JSON response)
├─────────────────┤
│ apps: [PromoApp]│──────┐
│ promoRules: {}  │      │
└─────────────────┘      │
                         ▼
              ┌─────────────────┐
              │    PromoApp     │
              ├─────────────────┤
              │ id: String      │
              │ name: String    │
              │ appStoreID: Str │
              │ iconURL: URL    │
              │ category: String│
              │ tagline: {...}  │───▶ LocalizedText
              └─────────────────┘

┌─────────────────┐
│   PromoConfig   │ (Client-side configuration)
├─────────────────┤
│ jsonURL: URL    │
│ currentAppID: St│
│ delegate: weak  │
└─────────────────┘

┌─────────────────┐
│   PromoEvent    │ (Analytics event)
├─────────────────┤
│ .impression(id) │
│ .tap(id)        │
└─────────────────┘
```

---

## Entities

### 1. AppCatalog

Root entity representing the complete JSON response from the remote endpoint.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `apps` | `[PromoApp]` | Yes | Array of promotable apps |
| `promoRules` | `[String: [String]]` | No | Maps host app ID → allowed promo app IDs |

**Validation Rules:**
- `apps` array MUST contain at least one item
- Each app ID in `promoRules` values MUST exist in `apps`
- If `promoRules` is empty or missing, all apps are shown (minus current app)

**Swift Declaration:**
```swift
struct AppCatalog: Codable, Sendable {
    let apps: [PromoApp]
    let promoRules: [String: [String]]?
}
```

---

### 2. PromoApp

Represents a single promotable app in the FinePocket portfolio.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | `String` | Yes | Unique identifier (e.g., "finebill") |
| `name` | `String` | Yes | Display name (e.g., "FineBill") |
| `appStoreID` | `String` | Yes | App Store numeric ID (e.g., "1234567890") |
| `iconURL` | `URL` | Yes | HTTPS URL to app icon image |
| `category` | `String` | Yes | Category label (e.g., "생산성", "독서") |
| `tagline` | `LocalizedText` | Yes | Localized tagline object |

**Validation Rules:**
- `id` MUST be unique across all apps
- `id` MUST be lowercase alphanumeric with optional hyphens
- `appStoreID` MUST be numeric string (App Store format)
- `iconURL` MUST use HTTPS scheme
- `category` MUST NOT be empty

**Swift Declaration:**
```swift
struct PromoApp: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let appStoreID: String
    let iconURL: URL
    let category: String
    let tagline: LocalizedText
}
```

---

### 3. LocalizedText

Contains tagline text in multiple languages with English as required fallback.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `en` | `String` | Yes | English text (required fallback) |
| `ko` | `String` | No | Korean text |
| `ja` | `String` | No | Japanese text |

**Validation Rules:**
- `en` MUST NOT be empty
- Optional fields (`ko`, `ja`) can be null or omitted

**Computed Property:**
- `localized: String` - Returns appropriate text based on device locale, fallback to `en`

**Swift Declaration:**
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

### 4. PromoConfig

Client-side configuration provided by the host app.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `jsonURL` | `URL` | Yes | Remote JSON endpoint URL |
| `currentAppID` | `String` | Yes | Host app identifier to exclude |
| `eventDelegate` | `PromoEventDelegate?` | No | Weak delegate for analytics events |

**Validation Rules:**
- `jsonURL` MUST use HTTPS scheme
- `currentAppID` MUST match one of the app IDs in the catalog

**Swift Declaration:**
```swift
struct PromoConfig: Sendable {
    let jsonURL: URL
    let currentAppID: String
}
```

---

### 5. PromoEvent

Analytics event types delegated to host app.

| Case | Associated Value | Description |
|------|------------------|-------------|
| `.impression` | `appID: String` | App row appeared in viewport |
| `.tap` | `appID: String` | User tapped on app row |

**Swift Declaration:**
```swift
enum PromoEvent: Sendable {
    case impression(appID: String)
    case tap(appID: String)
}
```

---

### 6. PromoEventDelegate

Protocol for receiving analytics events.

**Swift Declaration:**
```swift
protocol PromoEventDelegate: AnyObject, Sendable {
    @MainActor
    func promoService(_ service: PromoService, didEmit event: PromoEvent)
}
```

---

## State Transitions

### PromoService Load State

```
                    ┌──────────┐
                    │   idle   │
                    └────┬─────┘
                         │ loadApps()
                         ▼
                    ┌──────────┐
                    │ loading  │
                    └────┬─────┘
                         │
           ┌─────────────┼─────────────┐
           │             │             │
           ▼             ▼             ▼
    ┌──────────┐  ┌──────────┐  ┌──────────┐
    │  loaded  │  │  cached  │  │  empty   │
    │ (fresh)  │  │ (stale)  │  │ (retry)  │
    └──────────┘  └──────────┘  └────┬─────┘
                                     │ retry
                                     ▼
                               ┌──────────┐
                               │ loading  │
                               └──────────┘
```

### Cache Lifecycle

```
┌─────────────┐     save()      ┌─────────────┐
│   empty     │ ───────────────▶│   valid     │
└─────────────┘                 └──────┬──────┘
      ▲                                │
      │ clear() or                     │ 24h elapsed
      │ app deleted                    ▼
      │                         ┌─────────────┐
      └─────────────────────────│   expired   │
                                └─────────────┘
```

---

## JSON Schema Reference

See `contracts/catalog-schema.json` for the complete JSON Schema definition.
