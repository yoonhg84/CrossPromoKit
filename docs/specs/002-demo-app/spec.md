# Feature Specification: CrossPromoKit Demo App

**Feature Branch**: `002-demo-app`
**Created**: 2026-01-19
**Status**: Draft
**Input**: User description: "Build CrossPromoKit Demo App - Example app within the package for demonstrating features, capturing screenshots for README documentation, and testing different states"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View Demo Promotion List (Priority: P1)

As a developer evaluating CrossPromoKit, I want to run the Example app and see a realistic promotion list so that I can understand how the package works in a real app context.

**Why this priority**: This is the core demonstration value - developers must see the package in action to understand its capabilities and decide whether to adopt it.

**Independent Test**: Can be fully tested by launching the Example app and viewing the "More Apps" section with fictional apps displayed.

**Acceptance Scenarios**:

1. **Given** I have cloned the CrossPromoKit repository, **When** I open and run the Example project in Xcode, **Then** the app launches successfully on simulator or device
2. **Given** the Example app is running, **When** I navigate to the Settings tab, **Then** I see a "More Apps" section with a list of promotional apps
3. **Given** I am viewing the promotion list, **When** I look at each app row, **Then** I see the app icon, name, category label, and tagline
4. **Given** the Example app simulates "PhotoMagic" as the current app, **When** I view the promotion list, **Then** PhotoMagic is NOT shown in the list (only other apps appear)

---

### User Story 2 - Test App Store Overlay (Priority: P2)

As a developer evaluating CrossPromoKit, I want to tap on a promoted app and see the App Store overlay so that I can verify the integration works correctly.

**Why this priority**: This demonstrates the conversion action - the key functionality that makes cross-promotion valuable.

**Independent Test**: Can be tested by tapping any app row and verifying either the SKOverlay appears (on device) or graceful handling occurs (on simulator).

**Acceptance Scenarios**:

1. **Given** I am viewing the promotion list on a physical device, **When** I tap on an app row, **Then** an in-app App Store overlay appears
2. **Given** I am viewing the promotion list on simulator, **When** I tap on an app row, **Then** I see a fallback alert explaining App Store is unavailable on simulator
3. **Given** the App Store overlay is displayed, **When** I dismiss it, **Then** I return to the promotion list without issues

---

### User Story 3 - Capture Screenshots for Documentation (Priority: P3)

As a package maintainer, I want the Example app to provide screenshot-ready UI states so that I can easily capture images for README documentation.

**Why this priority**: High-quality screenshots improve package adoption by showing professional documentation.

**Independent Test**: Can be tested by navigating to each state and verifying the UI is visually clean and suitable for screenshots.

**Acceptance Scenarios**:

1. **Given** I am running the Example app, **When** I view the normal loaded state, **Then** the UI displays a clean promotion list suitable for hero screenshot
2. **Given** I have configured the app for loading state, **When** I view the promotion section, **Then** I see a loading indicator state suitable for screenshot
3. **Given** I have configured the app for empty state, **When** I view the promotion section, **Then** I see an empty state with "Try Again" option suitable for screenshot
4. **Given** I have configured the app for error state, **When** I view the promotion section, **Then** I see an error message state suitable for screenshot

---

### User Story 4 - Test Localization (Priority: P4)

As a developer, I want to test the Example app in different languages so that I can verify localization works correctly.

**Why this priority**: Localization is an important feature but secondary to core functionality demonstration.

**Independent Test**: Can be tested by changing simulator/device language and verifying taglines change accordingly.

**Acceptance Scenarios**:

1. **Given** my device language is set to English, **When** I view the promotion list, **Then** all taglines are displayed in English
2. **Given** my device language is set to Korean, **When** I view the promotion list, **Then** all taglines are displayed in Korean
3. **Given** my device language is set to Japanese, **When** I view the promotion list, **Then** all taglines are displayed in Japanese
4. **Given** my device language is set to an unsupported language (e.g., French), **When** I view the promotion list, **Then** all taglines fall back to English

---

### Edge Cases

- What happens when network request fails and no cache exists? → Display empty state with "Try Again" button
- What happens when JSON URL returns invalid data? → Display error state with user-friendly message
- What happens when app icon fails to load? → Display placeholder icon
- What happens on first launch with no network? → Display offline empty state
- What happens when running on simulator without App Store? → Show fallback alert with explanation

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Example app MUST be included in the CrossPromoKit Swift Package as a separate target
- **FR-002**: Example app MUST simulate a fictional "PhotoMagic" app as the host application
- **FR-003**: Example app MUST include a demo JSON file with 5 fictional apps (WeatherPal, FitTrack, NoteFlow, BudgetWise, PhotoMagic)
- **FR-004**: Example app MUST provide a Settings screen with embedded `MoreAppsView`
- **FR-005**: Example app MUST exclude PhotoMagic from the displayed promotion list (as it's the "current" app)
- **FR-006**: Example app MUST support testing different UI states: loading, loaded, empty, error
- **FR-007**: Example app MUST handle SKOverlay unavailability gracefully (simulator fallback)
- **FR-008**: Example app MUST support all three languages: English, Korean, Japanese
- **FR-009**: Demo JSON MUST include localized taglines for each fictional app in en, ko, ja
- **FR-010**: Example app MUST use local bundled JSON for demo (not remote URL) for reliability
- **FR-011**: Example app MUST demonstrate the `PromoEventDelegate` by logging events to console
- **FR-012**: Example app MUST be buildable and runnable without any external dependencies or API keys

### Key Entities

- **DemoApp**: Represents a fictional app in the demo catalog with id, name, appStoreID, iconURL, category, and localized taglines
- **DemoState**: Enumeration of UI states for testing: loading, loaded, empty, error
- **DemoConfig**: Configuration for the Example app including current app ID and JSON source

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Example app builds and runs successfully on iOS 17+ simulator within 30 seconds of opening project
- **SC-002**: All 4 fictional apps (excluding PhotoMagic) are displayed in the promotion list
- **SC-003**: App correctly displays content in all 3 supported languages when device language changes
- **SC-004**: All 4 UI states (loading, loaded, empty, error) are achievable for screenshot capture
- **SC-005**: Tapping an app row triggers either SKOverlay (device) or fallback alert (simulator) 100% of the time
- **SC-006**: Example app requires zero configuration or setup beyond opening in Xcode and pressing Run

## Assumptions

- Developers evaluating the package have Xcode 16+ installed
- The Example app target is iOS 17+ to match the main package requirements
- Fictional app icons will be bundled as assets or use SF Symbols as placeholders
- The demo JSON will be bundled within the Example app target, not fetched remotely
- SKOverlay is unavailable on simulator, so fallback UI is required for simulator testing
- Screenshots will be captured manually by the maintainer; no automated screenshot tool is required
