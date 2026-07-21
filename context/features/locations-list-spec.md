# Locations List Spec

## Overview

The Locations tab's first real screen and a fresh vertical slice through all Clean Architecture layers, this time for the `/location` resource. Replaces the `PlaceholderView` in `LocationsTab` with a **paginated, infinite-scrolling** list of locations. This is a brand-new resource — no `Location` domain entity or Data-layer stack exists yet, so this feature introduces the full stack (endpoint, DTOs, repository, use case, view model, view). Follows the Module Structure, Use Case Convention, Repository Convention, and Coordinator Convention sections of the project overview.

Structurally this is the closest sibling to the **Characters List**: `/location` is a plain paginated list with the same `info` + `results` response shape, so this feature reuses that screen's paginated pattern — infinite scroll via a footer sentinel, generation-token race guard, skeleton/empty/error states — rather than the Episodes List's load-all approach.

There are no dedicated screenshots for this screen — reuse the visual language of the Characters List screenshots (cards/rows on a light-gray/dark background, green accent, rounded corners) and the "RICKVERSE" eyebrow + large-title header. Locations have **no image**, so rows are text-only cards.

## Requirements

### UI

Header, matching the Characters List:
- "RICKVERSE" eyebrow label, "Locations" large title, and a total-count badge (e.g. "126 total") driven by the API's `info.count`.

List body:
- A scrollable list of location cards, ordered as the API returns them (by `id` ascending).
- Each **row/card** shows: location **name** (primary), **type** (e.g. "Planet", "Space station"), and **dimension** (e.g. "Dimension C-137"). Show "—" when `type` or `dimension` is an empty string (the API returns `""`, e.g. `dimension: ""` on some locations).
- A small residents count is acceptable but **optional** — the API gives resident URLs, so the count (`residents.count`) is available without extra requests. Include it only if it reads well ("12 residents"); otherwise omit. Do not fetch residents.
- **Rows are not tappable** in this phase — Location Detail is a separate follow-up feature. Keep `LocationsCoordinator.Route` empty; do not add a route.
- Light and dark mode supported.

### API Reference (Rick and Morty API)

Base URL: `https://rickandmortyapi.com/api`

| Endpoint | Description |
|----------|-------------|
| `GET /location` | All locations, paginated (20 per page, `?page=`). **126 locations across 7 pages.** |
| `GET /location/{id}` | Single location by ID (Location Detail feature — not used here) |
| `GET /location/{id},{id},…` | Multiple locations by comma-separated IDs (not used here) |

Query parameters for `GET /location` (this feature uses only `page`; the rest are listed for context / future Search & Filter):

| Param | Values |
|-------|--------|
| `page` | page number, starts at 1 |
| `name` | free-text location-name filter |
| `type` | location classification filter (e.g. `Planet`) |
| `dimension` | dimension filter (e.g. `C-137`) |

List response shape — `info` + `results` (identical structure to `/character` and `/episode`):

```json
{
  "info": {
    "count": 126,
    "pages": 7,
    "next": "https://rickandmortyapi.com/api/location/?page=2",  // null on last page
    "prev": null
  },
  "results": [ { ...location... } ]
}
```

Location object:

```json
{
  "id": 1,
  "name": "Earth (C-137)",
  "type": "Planet",
  "dimension": "Dimension C-137",
  "residents": [ "https://rickandmortyapi.com/api/character/38", "..." ],
  "url": "https://rickandmortyapi.com/api/location/1",
  "created": "2017-11-10T12:42:04.162Z"
}
```

- Note: like `/character`, `GET /location` returns **404 when no results match** a filter. This feature applies no filters, so a 404 isn't expected — but map 404 → empty results in the repository anyway, mirroring `CharactersRepository`, so the future Search & Filter feature inherits the behavior for free.
- Note: `type` and `dimension` can be empty strings (`""`) — handle in the mapper/view (show "—"), do not treat as an error.

### Data & Networking

New `Data/Network/Location/` folder (one folder per API resource, per Module Structure), holding the DTO + mapping + endpoint:

- **`LocationEndpoint`** (`Endpoint`) — `case list(LocationsRequest)` → path `location`, with `page` (and later `name` / `type` / `dimension`) as query parameters, mirroring `CharacterEndpoint.list`. Add a private `LocationsRequestDTO: Encodable` in the endpoint file (like `CharactersRequestDTO`) so `nil` fields drop out of the query. Only `page` is wired now; leave the filter params for Search & Filter.
- **DTOs** — `LocationDTO` mirroring the JSON above, plus a paginated response DTO `LocationsResponseDTO { info: PageInfoDTO; results: [LocationDTO] }`. **Reuse the existing `PageInfoDTO`** (currently declared in `CharacterDTO.swift`) — do **not** duplicate it. If sharing it from the character file reads oddly, note it in the PR; do not move it without asking (surgical-changes rule).
- **Mapping** `LocationDTO` → domain `Location`: `residents` URLs → `residentIDs` (parse trailing ID from each URL, same approach as the character/episode mappers); `name`, `type`, `dimension` carried through as-is; `url`, `created` decoded but not carried into the domain entity.
- **Domain — `Location` entity** per the project overview draft: `id: Int`, `name: String`, `type: String`, `dimension: String`, `residentIDs: [Int]`. Plain `Identifiable, Equatable` struct in `Domain/Entities/`.
- **Domain — `LocationsRepository`** protocol in `Domain/Repositories/`, per the Repository Convention (methods take a `…Request` struct, return a `…Response` struct):
  - `func locations(matching request: LocationsRequest) async throws -> LocationsResponse`. The protocol is `Sendable` (like `CharactersRepository: Sendable`), required for the `@MainActor` view model to hold it under Swift 6 strict concurrency.
  - `LocationsRequest { var page: Int = 1 }` (name/type/dimension filters added later by Search & Filter). `LocationsResponse { locations: [Location]; totalCount: Int; hasNextPage: Bool }` — same paging metadata as `CharactersResponse`.
  - Naming note: `LocationsRepository` (plural, paginated list). There's no batch/detail location repository yet, so no near-collision to flag — unlike the Episodes case. When Location Detail is built it should follow the same `LocationDetailRepository` naming used for `CharacterDetailRepository`.
  - Implementation `DefaultLocationsRepository` in `Data/Repositories/` — builds `LocationEndpoint.list`, maps DTOs to domain, `hasNextPage = info.next != nil`, `totalCount = info.count`, and maps a 404 to an empty `LocationsResponse` (mirroring `DefaultCharactersRepository`).
- **Use case** — **do not add one.** Fetching a page of locations is a single call to a single repository with no orchestration, mapping, or second data source — exactly the pass-through the Use Case Convention's guardrail says to skip (as Character Detail did when it removed `FetchCharactersUseCase`). The view model depends on the **`LocationsRepository` protocol** directly; that protocol is the mockable seam for tests. Introduce a use case only if a real business rule appears later.
- **DI (`AppContainer`)** — add `locationsRepository: LocationsRepository`, wire `DefaultLocationsRepository` into `.live` and a new `PreviewLocationsRepository` into `.preview`, and add `makeLocationsListViewModel()` that builds the view model over the `LocationsRepository` protocol.

### Presentation

- `Presentation/Locations/List/` — new folder holding `LocationsListView`, `LocationsListViewModel`, and the row/card subview (extract views past ~100 lines per coding standards).
- **`LocationsListViewModel`** (`@Observable @MainActor`), depends on the `LocationsRepository` protocol only (mockable seam for unit tests). `CharactersListViewModel` is the template, but it carries search + status-filter machinery this screen does not have — treat it as "the Characters list view model **minus** search/filter." Be explicit about what to carry over vs. drop:
  - **Keep:** the `LoadState` enum (`idle` / `loading` / `loaded` / `empty` / `failed`); `onAppear()` (loads page 1 once, no-op unless `.idle`); `retry()` (re-runs after a first-page failure); `reload()` (pull-to-refresh, resets to page 1); the private `performFirstPageLoad()` / `loadNextPage()` split; `totalCount`; `characters`-equivalent `locations: [Location]`; `isLoadingNextPage`; `hasNextPage`; `currentPage`.
  - **Drop (out of scope — Search & Filter):** the `StatusFilter` enum, `searchText`, `statusFilter`, `scheduleSearch()` / `scheduleReload(debounced:)`, the `searchDebounce` init parameter and the `reloadTask` it drives. Without search/filter there's no debounced/superseding *first-page* reload path, so `reloadTask` and the `CancellationError` handling that supported it can go. `makeRequest(page:)` collapses to just `LocationsRequest(page:)`.
  - **Preserve two non-obvious behaviors verbatim** (they're subtle and the tests below depend on them):
    - **Generation-token race guard** — `generation` bumped at the start of each first-page load; results tagged with an older token are dropped. This still matters: pull-to-refresh can still be triggered while a load is in flight, so the guard is *not* search-specific.
    - **`paginationToken` footer re-arm** — the footer sentinel keys its `.task(id: paginationToken)`; `paginationToken` is bumped on **every** exit of `loadNextPage()` (success *and* failure, via `defer`) so a failed next-page attempt (API HTTP 429) re-arms the still-visible sentinel and retries, with a ~1s backoff before re-arming on failure. My spec's earlier phrase "footer-sentinel `onAppear`" was loose — it is a `.task(id:)` on the token, not a plain `onAppear`.
  - **Infinite scroll**: `loadNextPageIfNeeded()` (guarded by `hasNextPage && !isLoadingNextPage`) fetches the next page, appends results, stops when `hasNextPage` is false. A page-N (N > 1) failure must **not** blow away already-loaded items — it keeps them and re-arms the sentinel (see above).
  - **First-load-vs-reload skeleton**: keep the `isFirstLoad = loadState != .loaded` guard so a pull-to-refresh over existing content does **not** flash to the full-screen skeleton (content stays until the new page swaps in).
  - Exposes `totalCount` for the badge and `locations: [Location]` for the view.
- **`LocationsTab`** — replace the `PlaceholderView` with `LocationsListView` built via `container.makeLocationsListViewModel()`, keeping the `NavigationStack` bound to the coordinator's (still-empty) path. `TabBarView` currently constructs `LocationsTab(coordinator:)` **without** a container — update that call site to pass `container`, mirroring `CharactersTab` / `EpisodesTab`.
- **States**: skeleton/shimmer rows while the first page loads, empty state if the list is somehow empty, error state with a Retry button on first-page failure. Reuse the Characters list's skeleton/state styling for consistency.

### Behavior

- On appear, fetch page 1 and render the cards.
- Infinite scroll loads subsequent pages as the user scrolls; stop when `info.next` is null (page 7).
- Pull-to-refresh reloads page 1 with a fresh generation token, replacing the list.
- First-page failure → full-screen error state with Retry. Later-page failure → non-destructive footer error; already-loaded locations stay on screen.

## Testing

Per the project's testing guidance — cover logic, not wiring:
- **`LocationsListViewModel`**: state transitions (loading → loaded / empty / failed), the retry path, infinite-scroll page accumulation (appends page 2 onto page 1; stops when `hasNextPage` is false), and that a later-page failure doesn't discard loaded items (and that it re-arms `paginationToken`). The `isFirstLoad` skeleton guard: a `reload()` over already-`loaded` content stays `.loaded` rather than flashing to `.loading`. Race guard: a superseded reload doesn't overwrite fresher results (mirror the Characters list view model's race tests, verified to fail when the generation-token guard is removed — the mock must let two calls be in flight at once, e.g. a gated/awaitable stub). Mock the `LocationsRepository` protocol. Follow the existing Characters view model tests' timing approach: don't sleep on the wall clock — gate the mock so two calls can overlap for race tests, and yield-until-settled rather than sleeping fixed durations. The next-page failure backoff stays a hard-coded `Task.sleep` (matching the Characters view model — *not* injectable); the failure test cancels the next-page `Task` so the sleep is cut short and the `defer` re-arm still runs, exactly as `paginationTokenAdvancesOnFailure` does today.
- **`DefaultLocationsRepository`**: DTO → domain mapping (`residents` URLs → `residentIDs`, empty `type`/`dimension` passthrough), `hasNextPage`/`totalCount` derivation, and 404 → empty response — driven by real wire JSON through a stubbed `APIClient` (same approach as the existing repository tests).
- Skip the SwiftUI views and the empty coordinator — no logic to protect. No use case exists to test (intentionally — see Data & Networking).

## Out of Scope

- **Location Detail screen** (tapping a row, residents strip via batch character fetch) — separate follow-up feature; rows stay non-tappable and `LocationsCoordinator.Route` stays empty.
- Name / type / dimension search and filtering — Search & Filter feature (the endpoint's filter params are stubbed but unwired).
- Any batch/single location fetch (`/location/{id}` or `/location/{id},{id}`) — Location Detail feature.
- Favorites / SwiftData.

## References

- @context/project-overview.md (Module Structure, Use Case Convention, Repository Convention, Coordinator Convention, API Architecture, Data Model draft for `Location`)
- @context/coding-standards.md
- @context/features/characters-list-spec.md (paginated list pattern, header, states, infinite scroll, race-guard, 404→empty)
- @context/features/episodes-list-spec.md (sibling resource-list slice; contrast: load-all vs. this feature's infinite scroll)
- @context/screenshots/characters-ui-light.png / characters-ui-dark.png (visual language reference)
- API docs: https://rickandmortyapi.com/documentation#location
