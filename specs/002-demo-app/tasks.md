# Tasks: CrossPromoKit Demo App

**Input**: Design documents from `/specs/002-demo-app/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Tests**: Not explicitly requested - tests are optional for this demo app feature.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

- **Project Type**: iOS Example App within Swift Package
- **Base Path**: `Example/CrossPromoDemo/CrossPromoDemo/`
- Xcode project: `Example/CrossPromoDemo/CrossPromoDemo.xcodeproj`

---

## Phase 1: Setup (Xcode Project Initialization)

**Purpose**: Create Xcode project structure and configure for local package dependency

- [X] T001 Create Example directory structure at `Example/CrossPromoDemo/`
- [X] T002 Initialize Xcode project `CrossPromoDemo.xcodeproj` with iOS 17.0+ target and Swift 6
- [X] T003 Configure project to use `swiftLanguageModes: [.v6]` in Build Settings
- [X] T004 Add local CrossPromoKit package dependency via File → Add Package Dependencies → Add Local
- [X] T005 [P] Create `MockData/` directory in `Example/CrossPromoDemo/CrossPromoDemo/MockData/`
- [X] T006 [P] Create `Helpers/` directory in `Example/CrossPromoDemo/CrossPromoDemo/Helpers/`
- [X] T007 [P] Create `Resources/` directory in `Example/CrossPromoDemo/CrossPromoDemo/Resources/`

---

## Phase 2: Foundational (Mock Data & Core Infrastructure)

**Purpose**: Create demo data and core helpers that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T008 Create demo-apps.json with 5 fictional apps in `Example/CrossPromoDemo/CrossPromoDemo/MockData/demo-apps.json`
- [X] T009 [P] Create DemoState enum (normal, loading, empty, error) in `Example/CrossPromoDemo/CrossPromoDemo/Helpers/DemoState.swift`
- [X] T010 [P] Create DemoEventHandler implementing PromoEventDelegate in `Example/CrossPromoDemo/CrossPromoDemo/Helpers/DemoEventHandler.swift`
- [X] T011 Create CrossPromoDemoApp.swift with @main entry point in `Example/CrossPromoDemo/CrossPromoDemo/CrossPromoDemoApp.swift`
- [X] T012 Create ContentView.swift with TabView structure (Settings, Debug) in `Example/CrossPromoDemo/CrossPromoDemo/ContentView.swift`

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - View Demo Promotion List (Priority: P1) 🎯 MVP

**Goal**: Developer can run Example app and see realistic promotion list with 4 fictional apps

**Independent Test**: Launch app → Navigate to Settings tab → Verify "More Apps" section shows WeatherPal, FitTrack, NoteFlow, BudgetWise (PhotoMagic excluded)

### Implementation for User Story 1

- [X] T013 [US1] Create SettingsView.swift with List containing "More Apps" section in `Example/CrossPromoDemo/CrossPromoDemo/SettingsView.swift`
- [X] T014 [US1] Integrate MoreAppsView from CrossPromoKit in SettingsView with currentAppID="photomagic"
- [X] T015 [US1] Configure PromoService to load from bundled demo-apps.json via Bundle.main
- [X] T016 [US1] Wire DemoEventHandler to PromoService for console logging
- [X] T017 [US1] Verify PhotoMagic exclusion works (only 4 apps displayed)

**Checkpoint**: User Story 1 complete - App launches and shows promotion list

---

## Phase 4: User Story 2 - Test App Store Overlay (Priority: P2)

**Goal**: Developer can tap promoted app and see SKOverlay (device) or fallback alert (simulator)

**Independent Test**: Tap any app row → Verify SKOverlay appears (device) OR fallback alert appears (simulator)

### Implementation for User Story 2

- [X] T018 [US2] Verify SKOverlay trigger on app row tap (inherits from CrossPromoKit MoreAppsView)
- [X] T019 [US2] Add simulator detection using #if targetEnvironment(simulator)
- [X] T020 [US2] Create fallback alert for simulator explaining "App Store unavailable on simulator"
- [X] T021 [US2] Verify overlay dismissal returns cleanly to promotion list

**Checkpoint**: User Story 2 complete - Tap interaction works on both device and simulator

---

## Phase 5: User Story 3 - Capture Screenshots for Documentation (Priority: P3)

**Goal**: Maintainer can force different UI states (loading, empty, error, normal) for screenshot capture

**Independent Test**: Use Debug tab → Select each state → Verify UI changes appropriately for screenshots

### Implementation for User Story 3

- [X] T022 [US3] Create DebugView.swift with TabView Debug tab content in `Example/CrossPromoDemo/CrossPromoDemo/DebugView.swift`
- [X] T023 [US3] Add Picker for DemoState selection (normal, loading, empty, error) in DebugView
- [X] T024 [US3] Create @Observable DemoViewModel to manage shared state across views
- [X] T025 [US3] Update SettingsView to respond to DemoState changes from DemoViewModel
- [X] T026 [US3] Implement loading state UI with ProgressView
- [X] T027 [US3] Implement empty state UI with "No apps available" message and "Try Again" button
- [X] T028 [US3] Implement error state UI with error message display

**Checkpoint**: User Story 3 complete - All 4 UI states accessible for screenshots

---

## Phase 6: User Story 4 - Test Localization (Priority: P4)

**Goal**: Developer can test app in different languages (en, ko, ja) and see localized taglines

**Independent Test**: Change device/simulator language → Launch app → Verify taglines display in selected language

### Implementation for User Story 4

- [X] T029 [US4] Create Localizable.xcstrings in `Example/CrossPromoDemo/CrossPromoDemo/Resources/Localizable.xcstrings`
- [X] T030 [P] [US4] Add English (en) localizations for UI strings
- [X] T031 [P] [US4] Add Korean (ko) localizations for UI strings
- [X] T032 [P] [US4] Add Japanese (ja) localizations for UI strings
- [X] T033 [US4] Verify taglines from demo-apps.json display correctly per device language
- [X] T034 [US4] Verify fallback to English for unsupported languages

**Checkpoint**: User Story 4 complete - Localization works for en, ko, ja

---

## Phase 7: Debug Tab Enhancements

**Goal**: Complete Debug tab with cache status, force refresh, and language info

### Implementation for Debug Tab

- [X] T035 Add cache status display section to DebugView (valid/expired/empty)
- [X] T036 Add "Force Refresh" button to clear cache and reload data in DebugView
- [X] T037 Add current language display section to DebugView
- [X] T038 Add instructions for changing language via Xcode scheme settings

**Checkpoint**: Debug tab fully functional with all diagnostic features

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Final improvements affecting multiple user stories

- [X] T039 [P] Add app icon and launch screen assets
- [X] T040 [P] Verify build succeeds with zero warnings
- [X] T041 [P] Test on iOS 17.0 simulator and verify all acceptance criteria
- [X] T042 Run quickstart.md validation steps and verify documentation accuracy

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - User stories can proceed sequentially in priority order (P1 → P2 → P3 → P4)
  - US1 is MVP - stop here for minimal demo
- **Debug Enhancements (Phase 7)**: Depends on US3 (DebugView exists)
- **Polish (Phase 8)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational - No dependencies on other stories
- **User Story 2 (P2)**: Depends on US1 (SettingsView with MoreAppsView exists)
- **User Story 3 (P3)**: Can start after Foundational - Creates DebugView independently
- **User Story 4 (P4)**: Can start after Foundational - Adds localizations independently

### Within Each User Story

- Models/Enums before Views
- Views before Integration
- Core implementation before refinement
- Story complete before moving to next priority

### Parallel Opportunities

**Phase 1 - Setup**:
```
T005, T006, T007 can run in parallel (creating directories)
```

**Phase 2 - Foundational**:
```
T009, T010 can run in parallel (DemoState.swift and DemoEventHandler.swift)
```

**Phase 6 - User Story 4**:
```
T030, T031, T032 can run in parallel (en, ko, ja localizations)
```

**Phase 8 - Polish**:
```
T039, T040, T041 can run in parallel (different concerns)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: App launches, shows 4 promotional apps
5. Deploy/demo if ready - minimal viable demo complete!

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add User Story 1 → App shows promotion list (MVP!)
3. Add User Story 2 → Tap triggers overlay/alert
4. Add User Story 3 → State testing for screenshots
5. Add User Story 4 → Localization support
6. Add Debug Enhancements → Full diagnostic capability
7. Polish → Production-ready demo

### Estimated Task Distribution

| Phase | Task Count | Parallel Opportunities |
|-------|------------|----------------------|
| Setup | 7 | 3 tasks |
| Foundational | 5 | 2 tasks |
| US1 (MVP) | 5 | 0 tasks |
| US2 | 4 | 0 tasks |
| US3 | 7 | 0 tasks |
| US4 | 6 | 3 tasks |
| Debug Enhancements | 4 | 0 tasks |
| Polish | 4 | 3 tasks |
| **Total** | **42** | **11 parallel** |

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at Phase 3 checkpoint for MVP demo
- SF Symbol icons: camera.filters, cloud.sun.fill, figure.run, note.text, dollarsign.circle.fill
- Current app ID for exclusion: "photomagic"
