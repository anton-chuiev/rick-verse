# Current Feature

<!-- Feature Name -->

## Status

<!-- Not Started|In Progress|Completed -->

Completed

## Goals

<!-- Goals & requirements -->

## Notes

<!-- Any extra notes -->

## History

<!-- Keep this updated. Earliest to latest -->

### 2026-07-09 — Characters List — Completed
- First full vertical slice through all Clean Architecture layers (Presentation → Domain → Data): paginated, searchable, filterable Characters list from the Rick and Morty API, replacing the tab placeholder
- UI: "RICKVERSE" eyebrow + "Characters" title + total-count badge, search field, status filter chips (All/Alive/Dead/Unknown), character cards (image, name, status dot + species, location, static outline heart, chevron); light + dark mode
- Tapping a card pushes a Character Detail placeholder via new `characterDetail(id:)` route on `CharactersCoordinator`
- Data/Networking: generic `APIClient` (URLSession + async/await), DTOs (`CharacterDTO`, `LocationRefDTO`, `PageInfoDTO`, paginated response), DTO → domain mapping, `CharacterRepository` protocol + impl, `FetchCharactersUseCase` (protocol + Default impl)
- Behavior: infinite scroll, debounced (~300 ms) name search, status filtering, pull-to-refresh, skeleton/empty/error states; API 404 mapped to empty results; removed `Data/MockData.swift`
- Post-review fixes: throttled Kingfisher avatar downloads + retry strategy for HTTP 429; self-healing pagination via footer sentinel keyed on `paginationToken`

### 2026-07-07 — Tab Bar (App Shell) — Completed
- App shell: `AppCoordinator` (splash→tabs), splash screen, 5-tab `TabView`, per-tab flow coordinator + `NavigationStack` with placeholder views
- Centralized design tokens in `Presentation/Common/` (`AppColor`, `AppSpacing`, `Color(light:dark:)`)
- Post-review fixes (swiftui-pro): migrated `TabView` to the `Tab(value:)` API; moved splash timing into `AppCoordinator.runSplash()`
- Post-review fix (swift-concurrency-pro): `runSplash()` handles `CancellationError` — cancelled splash task no longer forces the transition

### 2026-07-06
- Added `.gitignore`, removed `xcuserstate` from tracking
- Added Module Structure section to project-overview.md (layer-first, use case protocols, coordinator-per-flow); Tech Stack now lists Kingfisher as dependency

### 2026-07-03
- Initial commit and push of Xcode project
