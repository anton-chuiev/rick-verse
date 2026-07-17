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

### 2026-07-17 — Unit Tests (Characters List) — Completed
- First unit tests in the project: 46 covering the Characters List vertical slice (view model, DTO mapping, repository). **No production code changes** — every seam already existed (repository protocols, `APIClient` as a protocol, injected `searchDebounce`)
- Testing foundation: `Tests/` mirrors the app's layer-first structure (`Presentation/`, `Data/`, `Mocks/`); Swift Testing; placeholder `Tests/Tests.swift` removed; Tests target added to the project file
- Presentation: `CharactersListViewModel` — generation-token race guarding (a superseded load discarded even when it lands last; a stale next page not appended after reload), cancellation-vs-failure (cancelled first load → `.idle`, not `.failed`), search debounce (three keystrokes → one request), filter changes, load states, pagination
- Data: `ResourceURL.trailingID(from:)` edges; `CharacterDTO.toDomain()` + `Status(apiValue:)` decoded from real API-shaped JSON (covers `CodingKeys` too); `DefaultCharactersRepository` — 404 → empty page **and** every other error propagates (a too-broad catch would show "no results" on any network failure)
- Test doubles: `MockCharactersRepository` is a plain spy (used by most tests); the two race tests use a separate `SuspendingCharactersRepository` that holds calls open via continuations to force out-of-order completion — machinery kept out of the spy; `StubAPIClient` implements the `APIClient` protocol scripted with raw JSON, so repository tests exercise real DTO decoding; fixtures in `Tests/Mocks/Fixtures.swift`
- Determinism: no network, no wall clock — timing driven by the injected debounce and by releasing held calls. The next-page back-off (hard-coded ~1s `Task.sleep`, not injectable) is skipped by cancelling once the call is observed
- **Both race tests verified to fail** when their token guard is removed from production code (guards restored; `git diff` on `rick-verse/` confirmed empty)
- Reviews: swift-concurrency-pro found a real double-resume trap in the mock (`resume(at:)` didn't consume the continuation), `@unchecked Sendable` on `StubAPIClient` (→ `@MainActor`), and a dead hook — all fixed. swift-testing-pro found five `#expect(!x)` negations (defeat macro expansion → `== false`) and fixtures living inside a mock file — both fixed
- Decided **against** testing `URLSessionAPIClient` via `URLProtocol` stubbing: too much Foundation machinery for a thin client that rarely changes. Recorded in the spec's Out of Scope with the reasoning
- Findings: `trailingID` on a trailing-slash URL is actually correct (`split` drops the empty tail) — the spec's suspicion was wrong; pinned as current behavior. Both targets sit at `SWIFT_VERSION = 5.0` despite the project being documented as Swift 6, and the Tests target lacks the app's `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (hence explicit `@MainActor`) — noted, not addressed
- Docs: added `unit-tests-spec.md`; `ai-interaction.md` Workflow step 4 no longer defers testing, plus a new Testing section recording the conventions

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
