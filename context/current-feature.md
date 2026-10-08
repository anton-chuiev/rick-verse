# Current Feature

<!-- Feature Name -->

## Status

<!-- Not Started|In Progress|Completed -->

Not Started

## Goals

<!-- Goals & requirements -->

## Notes

<!-- Any extra notes -->

## History

<!-- Keep this updated. Earliest to latest. -->
<!-- Format per completed feature: date + name, one sentence of what shipped,
     then max 2–3 bullets for non-trivial decisions/gotchas worth remembering,
     then a `Details:` link to the spec. Full detail lives in the spec, not here.
     Minor milestones (setup, chore) get a single line, no bullets. -->

### 2026-10-08 — Characters Filter Scroll Reset (fix) — Completed
Switching filter/search on the Characters list now opens page 1 at the top; the page number was already reset, but the `ScrollView` kept its old offset and a next page could start mid-reload with the old page number + new filter.
- Fixed by simplifying: one in-flight `loadTask` (a first-page load cancels it, a cancelled load never applies its result, paging only starts when idle) replaces `generation` tokens, `reloadTask`, `isLoadingNextPage`
- Scroll-to-top lives in the view (`onChange` of filter/search), not the view model; leaving the screen mid-first-load no longer cancels it
- Details: `context/features/characters-filter-scroll-reset-spec.md`

### 2026-10-08 — Character Detail Tests — Completed
Unit tests for the Character Detail slice (shipped before the project had tests): view model, batch-episode repository, and single-character repository, all at 100% line coverage. No production changes.
- Unblocks the paused CI coverage gate (`feature/ci-lint-coverage`), where honest business-logic coverage was 76.3% < 80%
- `FetchEpisodeBatchUseCase` left untested as a pass-through, per the testing guidelines
- Details: `context/features/character-detail-tests-spec.md`

### 2026-10-02 — CI: Build & Test — Completed
First CI/CD stage — GitHub Actions `build-and-test` builds and runs the full test suite on every PR into `main` and push to `main`; `main` is protected by a ruleset (PR + green check required, no bypass).
- Repo made public (unlimited macOS minutes + rulesets on GitHub Free); Xcode pinned to 26.3, actions pinned by SHA; shared scheme + committed `Package.resolved`
- A deliberate red run surfaced a real bug: `upload-artifact` strips the common root, so the `.xcresult` is uploaded via its parent `build/` folder
- Merging now goes through GitHub PRs; marking a feature completed is the last commit in the PR, after CI is green
- Details: `context/features/ci-build-test-spec.md`

### 2026-07-21 — Favorites — Completed
Fifth slice and the project's first SwiftData layer — offline-capable favorites; toggle from Characters list + Character Detail, a new Favorites tab (newest-first, swipe-to-remove) that pushes Detail within its own stack.
- Cross-screen live updates via one shared `@Observable FavoritesStore` in the environment — `toggle` moves `favoriteIDs` (hearts) and `favorites` (list) together, optimistic with revert
- `DefaultFavoritesRepository` holds the `ModelContainer` (not a bare `ModelContext`) — a context doesn't retain its container, which was crashing tests; owning the container is Apple's documented practice. Tests surfaced two real bugs (this + `dateAdded` dropped in the model init)
- Removal shipped as swipe-only (spec said swipe/heart-tap); the Favorites card heart was dropped per request
- Details: `context/features/favorites-spec.md`

### 2026-07-21 — Episodes List — Completed
Third vertical slice — all episodes grouped by season; new paginated `/episode` stack alongside the existing by-ID batch stack.
- Load-all (no UI pagination): `FetchAllEpisodesUseCase` walks pages sequentially into a flat list; season grouping (parsing `S0xE0y`) lives in the view model
- Renamed the batch stack to `EpisodeBatch…` to read distinctly from the new plural `EpisodesRepository` (no behavior change)
- Details: `context/features/episodes-list-spec.md`

### 2026-07-21 — Locations List — Completed
Fourth vertical slice — paginated, infinite-scrolling `/location` list (text-only rows, no image); VM is the Characters list VM minus search/filter. No use case (pure repository pass-through).
- Reused `PageInfoDTO` (as Episode already does); 404→empty mirrors `DefaultCharactersRepository`; 40 new tests, all green
- `Suspending*` test mocks index held calls by absolute order — `resume(at:)` needs the absolute index (a resumed slot is retained as nil, not removed)
- Details: `context/features/locations-list-spec.md`

### 2026-07-17 — Unit Tests (Characters List) — Completed
First tests in the project — 46 across view model / DTO mapping / repository. No production changes; every seam already existed.
- Both race tests verified to fail when the generation-token guard is removed
- Chose against `URLProtocol`-stubbing the API client (too much Foundation machinery for a thin client)
- Details: `context/features/unit-tests-spec.md`

### 2026-07-15 — Character Detail — Completed
Second vertical slice — detail screen composing a single character + its episodes via batch fetch.
- `EpisodeRepository` hides the single-vs-array decode quirk; batch orchestration in `FetchEpisodesUseCase`
- Refactor (no behavior change): `CharacterRepository` → `CharactersRepository`, removed pass-through `FetchCharactersUseCase`, reorganized `Data/Network/` into `Core/` + `Character/` + `Episode/`
- Details: `context/features/character-detail-spec.md`

### 2026-07-09 — Characters List — Completed
First full vertical slice (Presentation → Domain → Data) — paginated, searchable, filterable list.
- Infinite scroll, debounced name search, status filter, pull-to-refresh; API 404 → empty results
- Self-healing pagination via footer sentinel keyed on `paginationToken`; throttled Kingfisher + HTTP 429 retry
- Details: `context/features/characters-list-spec.md`

### 2026-07-07 — Tab Bar (App Shell) — Completed
App shell — `AppCoordinator` (splash→tabs), 5-tab `TabView`, per-tab coordinator + `NavigationStack`; design tokens in `Presentation/Common/`.
- Details: `context/features/tab-bar-spec.md`

### 2026-07-06
- Added `.gitignore`, removed `xcuserstate` from tracking
- Added Module Structure section to project-overview.md (layer-first, use case protocols, coordinator-per-flow); Tech Stack now lists Kingfisher as dependency

### 2026-07-03
- Initial commit and push of Xcode project
