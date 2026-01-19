# Feature Specification: CrossPromoKit

**Feature Branch**: `001-cross-promo-kit`
**Created**: 2026-01-19
**Status**: Draft
**Input**: User description: "Build CrossPromoKit, a Swift Package for cross-promoting apps within the FinePocket app portfolio"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View Other FinePocket Apps (Priority: P1)

As a FinePocket app user, I want to discover other apps from the same developer so that I can find useful tools that complement my current app.

**Why this priority**: This is the core value proposition - users must be able to see and explore other FinePocket apps. Without this, the package has no purpose.

**Independent Test**: Can be fully tested by displaying a list of apps with their icons, names, and taglines. Delivers immediate discovery value.

**Acceptance Scenarios**:

1. **Given** I am in any FinePocket app's settings screen, **When** I navigate to the "More Apps" section, **Then** I see a list of other FinePocket apps (excluding the current app I'm using)
2. **Given** the app list is displayed, **When** I view an app entry, **Then** I see the app icon, name, category label, and a localized tagline in my device language
3. **Given** my device language is Korean, **When** I view an app entry, **Then** the tagline is displayed in Korean
4. **Given** my device language is not supported (not ko/en/ja), **When** I view an app entry, **Then** the tagline falls back to English

---

### User Story 2 - Open App in App Store (Priority: P2)

As a user who found an interesting app, I want to quickly view it in the App Store so that I can learn more and download it without leaving the current app context.

**Why this priority**: This enables the conversion action - users need a way to act on their interest. Depends on US1 for discovering apps first.

**Independent Test**: Can be tested by tapping any app row and verifying the in-app App Store overlay appears with the correct app.

**Acceptance Scenarios**:

1. **Given** I see a list of FinePocket apps, **When** I tap on an app row, **Then** an in-app App Store overlay appears showing that app's store page
2. **Given** the App Store overlay is displayed, **When** I dismiss the overlay, **Then** I return to the app list without any data loss or navigation issues
3. **Given** the App Store overlay is displayed, **When** I tap "Get" or "Open", **Then** the system handles the action appropriately (download or launch)

---

### User Story 3 - Offline Access (Priority: P3)

As a user with intermittent connectivity, I want to see the app list even when offline so that I can still discover other apps and potentially save them for later.

**Why this priority**: Enhances reliability but core discovery (US1) and action (US2) work without this in connected scenarios.

**Independent Test**: Can be tested by loading the app list once online, then enabling airplane mode and reopening the list.

**Acceptance Scenarios**:

1. **Given** I previously loaded the app list while online, **When** I open the "More Apps" section while offline, **Then** I see the cached list of apps
2. **Given** I am offline and have cached data, **When** I tap on an app row, **Then** I receive a graceful message that App Store access requires internet (no crash or error dialog)
3. **Given** cached data is older than 24 hours, **When** I open the "More Apps" section while online, **Then** the system automatically refreshes the data

---

### User Story 4 - Filtered Promotions (Priority: P4)

As a FinePocket product manager, I want to control which apps are promoted within each host app so that I can create relevant cross-promotion strategies.

**Why this priority**: Enables strategic control but requires basic functionality (US1-3) to be in place first.

**Independent Test**: Can be tested by configuring different promo rules for different host apps and verifying only allowed apps appear.

**Acceptance Scenarios**:

1. **Given** promo rules are configured for the current app, **When** I view the "More Apps" section, **Then** I only see apps that are allowed by the rules
2. **Given** no promo rules exist for the current app, **When** I view the "More Apps" section, **Then** I see all other FinePocket apps (excluding the current app)
3. **Given** the current app is "finebill", **When** I view the "More Apps" section, **Then** the "FineBill" app is never shown in the list

---

### Edge Cases

- What happens when the remote JSON URL is unreachable and no cache exists? → Display an empty state with a "Try Again" option
- What happens when the JSON contains invalid or malformed data? → Fall back to cached data if available, otherwise show empty state
- What happens when an app's icon URL fails to load? → Display a placeholder icon
- What happens when the App Store overlay fails to present? → Show a fallback alert offering to open the App Store app directly
- What happens when cached data expires while the app is in the foreground? → Continue showing current data, refresh in background

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Package MUST fetch app catalog from a configurable remote JSON endpoint
- **FR-002**: Package MUST cache fetched data locally with a 24-hour expiration policy
- **FR-003**: Package MUST serve cached data when network is unavailable
- **FR-004**: Package MUST support localized taglines in Korean (ko), English (en), and Japanese (ja)
- **FR-005**: Package MUST fall back to English tagline when user's language is not available
- **FR-006**: Package MUST exclude the current host app from the displayed list
- **FR-007**: Package MUST filter displayed apps based on configurable promo rules when rules exist
- **FR-008**: Package MUST show all other apps when no promo rules are configured
- **FR-009**: Package MUST provide a `MoreAppsView` component for embedding in settings screens
- **FR-010**: Package MUST provide a `PromoAppRow` component for displaying individual app entries
- **FR-011**: Package MUST display app icon, name, category label, and localized tagline for each app entry
- **FR-012**: Package MUST present an in-app App Store overlay when user taps an app row
- **FR-013**: Package MUST handle offline scenarios gracefully without crashes or intrusive error messages
- **FR-014**: Package MUST refresh cached data automatically when cache expires and network is available
- **FR-015**: Package MUST support the following target apps: FineBill, Bookary, FinePomo, Stedio, Littory
- **FR-016**: Package MUST display apps in the order defined in the JSON catalog (server-controlled ordering)
- **FR-017**: Package MUST provide a delegate mechanism for host apps to receive promo events (app impression, app tap)
- **FR-018**: Package MUST NOT collect or transmit analytics data directly; all event handling is delegated to host app

### Key Entities

- **PromoApp**: Represents a promotable app with identifier, display name, App Store ID, icon URL, category, and localized taglines
- **LocalizedTagline**: Contains tagline text in multiple languages (en, ko, ja) with English as required fallback
- **PromoRules**: Maps host app identifiers to arrays of allowed promotional app identifiers
- **AppCatalog**: Root entity containing the list of all PromoApps and the PromoRules dictionary
- **PromoEvent**: Represents an analytics event (impression, tap) with associated app identifier, delegated to host app for handling

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can view the "More Apps" list within 1 second of navigation (using cached data)
- **SC-002**: App list displays correctly in all three supported languages (ko, en, ja) with proper fallback
- **SC-003**: 100% of app tap interactions result in either App Store overlay or graceful offline message
- **SC-004**: Package functions fully offline when cached data is available (no crashes, no blocking errors)
- **SC-005**: Fresh data is fetched within 2 seconds on a standard mobile connection
- **SC-006**: Package can be integrated into a host app with a single line of code: `MoreAppsView(currentAppID: "appid")`
- **SC-007**: All 5 target apps (FineBill, Bookary, FinePomo, Stedio, Littory) are supported in the catalog

## Clarifications

### Session 2026-01-19

- Q: 앱 목록 정렬 순서는? → A: JSON에서 정의된 순서 (서버 제어)
- Q: Analytics 이벤트 수집 방식은? → A: 호스트 앱에 delegate로 이벤트 전달 (호스트가 처리)
- Q: Category 필드의 용도는? → A: 카테고리 레이블로 앱 row에 표시

## Assumptions

- The remote JSON endpoint will be hosted on GitHub (raw file) and will have high availability
- App icons are hosted externally and accessible via HTTPS URLs
- The App Store IDs provided in the JSON are valid and correspond to published apps
- Host apps using this package target iOS 17+ and support SwiftUI
- Users have previously granted network access permissions to the host app
- The in-app App Store overlay (SKOverlay) is available on all target iOS versions
