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

### 2026-07-21 — Episodes List — Completed
Third vertical slice — all episodes grouped by season; new paginated `/episode` stack alongside the existing by-ID batch stack.
- Load-all (no UI pagination): `FetchAllEpisodesUseCase` walks pages sequentially into a flat list; season grouping (parsing `S0xE0y`) lives in the view model
- Renamed the batch stack to `EpisodeBatch…` to read distinctly from the new plural `EpisodesRepository` (no behavior change)
- Details: `context/features/episodes-list-spec.md`

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
