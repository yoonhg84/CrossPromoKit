# Tasks: CrossPromoKit

**Input**: Design documents from `/specs/001-cross-promo-kit/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Not explicitly requested in spec. Test tasks are omitted.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

- **Swift Package**: `Sources/CrossPromoKit/`, `Tests/CrossPromoKitTests/` at repository root
- Package.swift at repository root

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Swift Package initialization and basic project structure

- [x] T001 Create Swift Package structure with `swift package init --type library --name CrossPromoKit`
- [x] T002 Configure Package.swift with iOS 17+ platform, Swift 6 tools version, StoreKit dependency
- [x] T003 [P] Create directory structure: Models/, Services/, Views/, Views/Components/, Design/, Protocols/, Extensions/
- [x] T004 [P] Configure .swiftlint.yml for code style enforcement

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core models and infrastructure that ALL user stories depend on

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T005 [P] Create LocalizedText model with localized computed property in Sources/CrossPromoKit/Models/LocalizedText.swift
- [x] T006 [P] Create PromoApp model (Codable, Sendable, Identifiable) in Sources/CrossPromoKit/Models/PromoApp.swift
- [x] T007 [P] Create AppCatalog model with apps array and optional promoRules in Sources/CrossPromoKit/Models/AppCatalog.swift
- [x] T008 [P] Create PromoConfig struct with jsonURL and currentAppID in Sources/CrossPromoKit/Models/PromoConfig.swift
- [x] T009 [P] Create PromoEvent enum (.impression, .tap) in Sources/CrossPromoKit/Models/PromoEvent.swift
- [x] T010 [P] Create PromoEventDelegate protocol in Sources/CrossPromoKit/Protocols/PromoEventDelegate.swift
- [x] T011 [P] Create Locale+Supported extension for language detection in Sources/CrossPromoKit/Extensions/Locale+Supported.swift
- [x] T012 [P] Create WarmEmbraceTokens with design system colors (Warm Coral, Soft Teal), spacing, and animation values in Sources/CrossPromoKit/Design/WarmEmbraceTokens.swift
- [x] T013 Create NetworkClient with async fetch method using URLSession in Sources/CrossPromoKit/Services/NetworkClient.swift

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - View Other FinePocket Apps (Priority: P1) MVP

**Goal**: Users can see a list of other FinePocket apps with icons, names, categories, and localized taglines

**Independent Test**: Display the app list from sample JSON. Verify icons load, names appear, taglines are localized.

### Implementation for User Story 1

- [x] T014 [US1] Create AsyncAppIcon component with placeholder and async image loading in Sources/CrossPromoKit/Views/Components/AsyncAppIcon.swift
- [x] T015 [US1] Create PromoAppRow view displaying icon, name, category label, and tagline in Sources/CrossPromoKit/Views/PromoAppRow.swift
- [x] T016 [US1] Create basic PromoService (@Observable, @MainActor) with apps array and loadApps() method in Sources/CrossPromoKit/Services/PromoService.swift
- [x] T017 [US1] Create MoreAppsView with List of PromoAppRow, loading state, and basic error handling in Sources/CrossPromoKit/Views/MoreAppsView.swift
- [x] T018 [US1] Add current app filtering logic (exclude currentAppID) in PromoService
- [x] T019 [US1] Add JSON order preservation (FR-016) to ensure apps display in server-defined order

**Checkpoint**: User Story 1 complete - users can view the app list with localized content

---

## Phase 4: User Story 2 - Open App in App Store (Priority: P2)

**Goal**: Users can tap an app to view it in an in-app App Store overlay (SKOverlay)

**Independent Test**: Tap any app row and verify SKOverlay appears with correct app. Dismiss and verify return to list.

**Dependency**: Requires US1 (app list display) to be complete

### Implementation for User Story 2

- [x] T020 [US2] Import StoreKit and implement SKOverlay presentation in PromoService in Sources/CrossPromoKit/Services/PromoService.swift
- [x] T021 [US2] Add tap gesture handler to PromoAppRow that triggers overlay presentation in Sources/CrossPromoKit/Views/PromoAppRow.swift
- [x] T022 [US2] Add eventDelegate support and emit .tap event when app row is tapped in PromoService
- [x] T023 [US2] Implement overlay dismiss handling and error fallback (open App Store app directly) in PromoService
- [x] T024 [US2] Add .impression event emission when app row appears in viewport using onAppear in PromoAppRow

**Checkpoint**: User Story 2 complete - users can tap apps and see App Store overlay

---

## Phase 5: User Story 3 - Offline Access (Priority: P3)

**Goal**: Users can view cached app list when offline; data refreshes automatically after 24 hours

**Independent Test**: Load app list online, enable airplane mode, reopen list. Verify cached data appears.

**Dependency**: Independent of US2, but uses US1 foundation

### Implementation for User Story 3

- [x] T025 [US3] Create CacheManager with UserDefaults storage for JSON and timestamp in Sources/CrossPromoKit/Services/CacheManager.swift
- [x] T026 [US3] Implement 24-hour expiration logic with timestamp comparison in CacheManager
- [x] T027 [US3] Integrate CacheManager into PromoService for save/load operations
- [x] T028 [US3] Implement three-tier fallback in loadApps(): Network → Cache → Empty State
- [x] T029 [US3] Create EmptyStateView with "Try Again" button and friendly message in Sources/CrossPromoKit/Views/EmptyStateView.swift
- [x] T030 [US3] Add graceful offline handling for SKOverlay (show alert instead of crashing) in PromoService
- [x] T031 [US3] Implement automatic refresh when cache expires and network becomes available

**Checkpoint**: User Story 3 complete - app works fully offline with cached data

---

## Phase 6: User Story 4 - Filtered Promotions (Priority: P4)

**Goal**: App list is filtered based on promoRules configuration; only allowed apps are shown

**Independent Test**: Configure promoRules for host app, verify only allowed apps appear. Remove rules, verify all apps appear.

**Dependency**: Uses US1 foundation, independent of US2/US3

### Implementation for User Story 4

- [x] T032 [US4] Add promoRules parsing and filtering logic to PromoService
- [x] T033 [US4] Implement filtering: if promoRules[currentAppID] exists, show only those apps
- [x] T034 [US4] Implement fallback: if no rules exist for currentAppID, show all apps (minus current)
- [x] T035 [US4] Ensure current app (currentAppID) is always excluded from results regardless of rules
- [x] T036 [US4] Add validation for promoRules referencing non-existent app IDs (log warning, skip invalid)

**Checkpoint**: User Story 4 complete - filtered promotions work as configured

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final improvements affecting multiple user stories

- [x] T037 [P] Add public API documentation comments to all public types and methods
- [x] T038 [P] Verify Sendable conformance for all models (Swift 6 strict concurrency)
- [x] T039 [P] Review and optimize Warm Embrace design system token usage across all views
- [x] T040 Code cleanup: remove unused imports, organize file structure
- [x] T041 Run quickstart.md validation - verify integration example works as documented
- [x] T042 Final build verification with `swift build` and ensure zero warnings

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1 (Setup) → Phase 2 (Foundational) → Phases 3-6 (User Stories) → Phase 7 (Polish)
                                            ↓
                                   [Can be parallelized]
```

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - US1 → US2 (US2 needs tap target from US1)
  - US1 → US3 (US3 needs data loading from US1)
  - US1 → US4 (US4 needs filtering base from US1)
  - US3 and US4 can run in parallel after US1
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

| Story | Can Start After | Dependencies on Other Stories |
|-------|-----------------|-------------------------------|
| US1 (P1) | Phase 2 | None |
| US2 (P2) | US1 complete | Needs PromoAppRow tap target |
| US3 (P3) | US1 complete | Needs loadApps() infrastructure |
| US4 (P4) | US1 complete | Needs filtering foundation |

### Within Each User Story

- Models/protocols before services
- Services before views
- Core implementation before integration
- Each story independently testable before next

### Parallel Opportunities

**Phase 1:**
- T003 and T004 can run in parallel

**Phase 2 (Maximum Parallelism):**
- T005, T006, T007, T008, T009, T010, T011, T012 - ALL can run in parallel (different files)
- T013 depends on T007 (uses AppCatalog model)

**After US1 Complete:**
- US3 (T025-T031) and US4 (T032-T036) can run in parallel

**Phase 7:**
- T037, T038, T039 can run in parallel

---

## Parallel Example: Phase 2 (Foundational)

```bash
# Launch all model/protocol creation tasks together:
Task: "T005 [P] Create LocalizedText model"
Task: "T006 [P] Create PromoApp model"
Task: "T007 [P] Create AppCatalog model"
Task: "T008 [P] Create PromoConfig struct"
Task: "T009 [P] Create PromoEvent enum"
Task: "T010 [P] Create PromoEventDelegate protocol"
Task: "T011 [P] Create Locale+Supported extension"
Task: "T012 [P] Create WarmEmbraceTokens"

# Then sequentially:
Task: "T013 Create NetworkClient" (uses AppCatalog)
```

---

## Parallel Example: After US1 Complete

```bash
# US3 and US4 can run in parallel:

# Developer A: User Story 3 (Offline)
Task: "T025 [US3] Create CacheManager"
Task: "T026 [US3] Implement 24-hour expiration"
# ...

# Developer B: User Story 4 (Filtering)
Task: "T032 [US4] Add promoRules parsing"
Task: "T033 [US4] Implement filtering logic"
# ...
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: App list displays with icons, names, localized taglines
5. Deploy/demo MVP

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → **MVP Ready!**
3. Add User Story 2 → Test tap + overlay → Enhanced conversion
4. Add User Story 3 → Test offline → Reliability upgrade
5. Add User Story 4 → Test filtering → Strategic control
6. Each story adds value without breaking previous stories

### Single Developer Strategy (Recommended)

```
Day 1: Phase 1 (Setup) + Phase 2 (Foundational)
Day 2: Phase 3 (US1 - MVP)
Day 3: Phase 4 (US2 - SKOverlay)
Day 4: Phase 5 (US3 - Caching)
Day 5: Phase 6 (US4 - Filtering) + Phase 7 (Polish)
```

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Swift 6 strict concurrency: All models must be Sendable
- iOS 17+: Use @Observable, not ObservableObject
