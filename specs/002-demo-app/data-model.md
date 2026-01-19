# Data Model: CrossPromoKit Demo App

**Feature Branch**: `002-demo-app`
**Date**: 2026-01-19
**Status**: Complete

## Overview

The Demo App uses the existing CrossPromoKit data models plus additional demo-specific types for state management and mock data configuration.

---

## Existing Package Models (Reference)

These models are provided by the CrossPromoKit package:

### PromoApp
Represents a promotable app in the catalog.

| Field | Type | Description |
|-------|------|-------------|
| id | String | Unique identifier (e.g., "photomagic") |
| name | String | Display name (e.g., "PhotoMagic") |
| appStoreID | String | App Store numeric ID |
| iconURL | URL | HTTPS URL to icon image |
| category | String | Category label (e.g., "Photo & Video") |
| tagline | LocalizedText | Localized description |

### LocalizedText
Container for multi-language text content.

| Field | Type | Description |
|-------|------|-------------|
| en | String | English text (required) |
| ko | String? | Korean text (optional) |
| ja | String? | Japanese text (optional) |

### AppCatalog
Root container for the JSON response.

| Field | Type | Description |
|-------|------|-------------|
| apps | [PromoApp] | Array of promotable apps |
| promoRules | [String: [String]]? | Optional filtering rules |

---

## Demo App Models (New)

### DemoState
Enumeration for controlling UI state during testing and screenshot capture.

| Case | Description |
|------|-------------|
| normal | Default state - shows loaded app list |
| loading | Simulates loading state with progress indicator |
| empty | Simulates empty state (no apps available) |
| error | Simulates error state with error message |

**Usage**: Used via picker/toggle in demo settings to force different view states.

### DemoAppInfo
Demo-specific representation for fictional apps with bundled icons.

| Field | Type | Description |
|-------|------|-------------|
| id | String | Unique identifier |
| name | String | Display name |
| appStoreID | String | Placeholder App Store ID |
| sfSymbol | String | SF Symbol name for icon |
| iconColor | Color | Background color for icon |
| category | String | Category label |
| tagline | LocalizedText | Localized description |

**Conversion**: Can be converted to `PromoApp` for package consumption.

---

## Demo Data Definition

### Fictional Apps

| ID | Name | SF Symbol | Color | Category |
|----|------|-----------|-------|----------|
| photomagic | PhotoMagic | camera.filters | Purple | Photo & Video |
| weatherpal | WeatherPal | cloud.sun.fill | Blue | Weather |
| fittrack | FitTrack | figure.run | Green | Health & Fitness |
| noteflow | NoteFlow | note.text | Orange | Productivity |
| budgetwise | BudgetWise | dollarsign.circle.fill | Teal | Finance |

### Localized Taglines

#### PhotoMagic
| Language | Tagline |
|----------|---------|
| en | Transform your photos with AI magic |
| ko | AI 마법으로 사진을 변환하세요 |
| ja | AIマジックで写真を変換 |

#### WeatherPal
| Language | Tagline |
|----------|---------|
| en | Your friendly weather companion |
| ko | 친근한 날씨 도우미 |
| ja | あなたの天気パートナー |

#### FitTrack
| Language | Tagline |
|----------|---------|
| en | Track your fitness journey |
| ko | 피트니스 여정을 추적하세요 |
| ja | フィットネスの旅を追跡 |

#### NoteFlow
| Language | Tagline |
|----------|---------|
| en | Notes that flow with your thoughts |
| ko | 생각과 함께 흐르는 노트 |
| ja | 思考と共に流れるノート |

#### BudgetWise
| Language | Tagline |
|----------|---------|
| en | Smart budgeting made simple |
| ko | 간단한 스마트 예산 관리 |
| ja | シンプルなスマート予算管理 |

---

## State Transitions

```
┌─────────────┐
│   Launch    │
└──────┬──────┘
       │
       ▼
┌─────────────┐     Demo Toggle
│   Normal    │◄──────────────────┐
│  (Loaded)   │                   │
└──────┬──────┘                   │
       │                          │
       │ Demo Toggle              │
       ▼                          │
┌─────────────┐                   │
│   Loading   │───────────────────┤
└─────────────┘                   │
       │                          │
       │ Demo Toggle              │
       ▼                          │
┌─────────────┐                   │
│    Empty    │───────────────────┤
└─────────────┘                   │
       │                          │
       │ Demo Toggle              │
       ▼                          │
┌─────────────┐                   │
│    Error    │───────────────────┘
└─────────────┘
```

---

## Relationships

```
DemoAppInfo (Demo)
      │
      │ converts to
      ▼
PromoApp (Package) ──────┐
      │                  │
      │ contained in     │
      ▼                  │
AppCatalog (Package)     │
      │                  │
      │ used by          │
      ▼                  │
PromoService (Package)◄──┘
      │
      │ provides to
      ▼
MoreAppsView (Package)
      │
      │ embedded in
      ▼
SettingsView (Demo)
```

---

## Validation Rules

### DemoState
- All cases are valid at any time
- Default state on launch: `normal`
- State changes take effect immediately

### DemoAppInfo
- `id` must be non-empty and unique
- `name` must be non-empty
- `sfSymbol` must be a valid SF Symbol name
- `iconColor` must be a valid SwiftUI Color
- `tagline.en` must be non-empty (other languages optional)

### Demo JSON
- Must be valid JSON format
- Must decode to `AppCatalog` structure
- Must contain exactly 5 apps
- PhotoMagic must be included (as current app to exclude)
