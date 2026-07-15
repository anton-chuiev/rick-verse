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

<!-- Keep this updated. Earliest to latest -->

### 2026-07-15 — Character Detail — Completed
- Second vertical slice: Character Detail screen composing two API resources (single character + its episodes via batch fetch), replacing the placeholder behind `CharactersCoordinator.Route.characterDetail(id:)`
- UI: stretchy edge-to-edge hero image (pinned to top on overscroll) with gradient scrim + name/status·species overlay and a static heart; About card (Gender, Type→"—" when empty, Origin, Last known location, "First seen in" from the first episode with a shimmer until it loads); Episodes section ("EPISODES · N", code badge + name + air date rows, not tappable); light + dark mode
- Domain/Data: `Episode` entity; `RMCharacter` extended with `gender`/`type`/`originName`; `CharacterEndpoint.detail(id:)`, `EpisodeEndpoint.batch(ids:)`, `EpisodeDTO` + mapping; `CharacterDetailRepository` + `EpisodeRepository` per the Repository Convention (episode repo hides the single-vs-array decode quirk and skips the network for empty ids); `FetchEpisodesUseCase` for batch orchestration; character fetch calls the repository directly per the guardrail
- Refactor (no behavior change): renamed `CharacterRepository` → `CharactersRepository` (+ Default/Preview); removed pass-through `FetchCharactersUseCase` (list VM depends on the repository directly); reorganized `Data/Network/` into `Core/` + `Character/` + `Episode/` subfolders
- Behavior: progressive loading via two independent state machines; full-screen error + Retry on character failure (404 = real error here); inline Retry for episodes; empty-section message; always fetch fresh by id
- Docs: added `character-detail-spec.md`; added Repository Convention, the direct-repository guardrail, and the `Data/Network/` structure to project-overview.md
- Pre-commit reviews (swiftui-pro / swift-concurrency-pro): adopted the list's VM-injection pattern (`@State private` + `@autoclosure` init); no concurrency issues

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
