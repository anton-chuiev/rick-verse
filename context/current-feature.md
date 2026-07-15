# Current Feature: Character Detail

<!-- Feature Name -->

## Status

<!-- Not Started|In Progress|Completed -->

In Progress
<!-- implementation done + builds; pending /feature review -->


## Goals

<!-- Goals & requirements -->

- Replace `CharacterDetailPlaceholderView` behind `CharactersCoordinator.Route.characterDetail(id:)` with a real Character Detail screen (`CharacterDetailView` + `CharacterDetailViewModel` in `Presentation/Characters/Detail/`, built via `AppContainer`)
- Hero layout: edge-to-edge square character image (Kingfisher, list's placeholder + retry behavior) under the nav bar, bottom gradient scrim with overlaid name + status dot · species; back chevron and a static non-interactive outline heart in the nav bar; light + dark mode
- About card: Gender, Type ("—" when empty), Origin, Last known location, "First seen in" (name of the first episode, fills in once episodes load)
- Episodes section: "EPISODES · N" header, rows with episode code badge (S01E01), name, air date; rows not tappable in this phase
- Data: `GET /character/{id}` via new `CharacterEndpoint.detail(id:)`; new `EpisodeEndpoint.batch(ids:)` for `GET /episode/{id},{id},…`; `EpisodeDTO` + mapping to new `Episode` domain entity (id, name, airDate, episodeCode, characterIDs)
- Extend `RMCharacter` with `gender`, `type`, `originName` (mapper + entity change; `created` stays DTO-only)
- Rename `CharacterRepository` → `CharactersRepository` (+ `Default…`/`Preview…` impls and file names), no behavior change
- New `CharacterDetailRepository` (`character(matching: CharacterDetailRequest) -> CharacterDetailResponse`) and `EpisodeRepository` (`episodes(matching: EpisodesRequest) -> EpisodesResponse`) per the Repository Convention; episode repo hides the single-vs-array decoding quirk and skips the network for empty ids
- `FetchEpisodesUseCase` (protocol + Default, one file); character fetch is a direct `CharacterDetailRepository` call from the view model (Use Case Convention guardrail) — no pass-through use case
- Remove `FetchCharactersUseCase` (pure pass-through predating the guardrail): `CharactersListViewModel` depends on `CharactersRepository` directly; update `AppContainer` and previews
- Behavior: skeleton for hero/About while the character loads; progressive loading — episodes load independently with their own shimmer and inline Retry; full-screen error + Retry on character failure (404 = real error here); empty-section message when a character has no episode IDs; always fetch fresh by id

## Notes

<!-- Any extra notes -->

- Spec: @context/features/character-detail-spec.md; conventions: Module Structure, Use Case Convention (incl. direct-repository guardrail), Repository Convention, Coordinator Convention in @context/project-overview.md
- No dedicated screenshots — reuse the Characters List visual language (cards, green accent, status dot colors, rounded corners) from @context/screenshots/characters-ui-light.png / -dark.png
- API gotchas: unknown character id → 404 `{"error":"Character not found"}` (real error, unlike the list's 404-as-empty); `GET /episode/{id}` with a single id returns an object, not a one-element array; `air_date` is snake_case
- "First seen in" derives from the first episode's name, not the API's `created` field
- Out of scope: favorites toggle (heart static), episode row navigation, Episodes List/season grouping, pull-to-refresh on detail, seeding from the already-loaded list character

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
