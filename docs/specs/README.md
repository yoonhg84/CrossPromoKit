# Frozen: historical specs

**These documents are frozen. Do not follow them as current documentation.**

They are the spec-kit output from the initial design of CrossPromoKit, written
2026-01-19 (`001-cross-promo-kit`) and `002-demo-app`. The spec-kit tooling was
removed in #26; these files were kept only as a record.

**Parts of them describe APIs that no longer exist.** For example the quickstart
guides show `MoreAppsView(currentAppID:)`, an initializer removed in d2e36db.
Never copy code out of this directory — the current API is in `README.md`,
`README.ko.md`, and the doc comments in `Sources/`.

The only live link between code and these documents is the requirement IDs:
`PromoService.swift` and `PromoServiceTests.swift` cite `FR-###`, which is
defined in the `spec.md` files here. That is why the specs are kept rather than
deleted.

Nothing here is updated when the code changes. Current work is tracked in GitHub
issues, not in these documents.

`tasks.md` (the spec-kit execution checklists) were deleted in #56 — the list of
completed work lives in the git history.
