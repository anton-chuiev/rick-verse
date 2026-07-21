# Episodes List Spec

## Overview

The Episodes tab's first real screen and a fresh vertical slice through all Clean Architecture layers, this time for the `/episode` resource. Replaces the `EpisodesTab` placeholder with a list of all episodes **grouped by season**: section headers ("Season 1", "Season 2", …) with compact episode rows under each (code · name · air date). Follows the Module Structure, Use Case Convention, Repository Convention, and Coordinator Convention sections of the project overview.

The `Episode` domain entity and its Data-layer stack already exist (added by the Character Detail feature), but only for **batch fetch by ID** (`GET /episode/{id},{id},…`). This feature adds the **paginated list** side of the resource — a new list endpoint case, a new paginated repository, and a use case that fetches all pages and hands the view model a flat `[Episode]` to group.

There are no dedicated screenshots for this screen — reuse the visual language of the Characters List screenshots (cards/rows on a light-gray/dark background, green accent, rounded corners) and the "RICKVERSE" eyebrow + large-title header.

## Requirements

### UI

Header, matching the Characters List:
- "RICKVERSE" eyebrow label, "Episodes" large title, and a total-count badge (e.g. "51 total") driven by the API's `info.count`.

Grouped list body:
- Episodes grouped into **season sections**, ordered by season number ascending. Each section has a header "Season N".
- Within a section, episodes are ordered by episode number ascending.
- Each episode **row** shows: episode code badge (e.g. "S01E01"), episode name, air date (as returned by the API, e.g. "December 2, 2013").
- **Rows are not tappable** in this phase — Episode Detail is a separate follow-up feature. Keep `EpisodesCoordinator.Route` empty; do not add a route.
- Season is derived from the episode **code** `S0xE0y` (parse the `S` segment), not from air date. Parsing lives in Presentation — the domain `Episode.episodeCode` stays the API's display string.
- Light and dark mode supported.

### API Reference (Rick and Morty API)

Base URL: `https://rickandmortyapi.com/api`

| Endpoint | Description |
|----------|-------------|
| `GET /episode` | All episodes, paginated (20 per page, `?page=`). **51 episodes across 3 pages.** |
| `GET /episode/{id},{id},…` | Multiple episodes by ID (already implemented — used by Character Detail, not by this feature) |

Query parameters for `GET /episode` (this feature uses only `page`; the rest are listed for context / future Search & Filter):

| Param | Values |
|-------|--------|
| `page` | page number, starts at 1 |
| `name` | free-text episode-name filter |
| `episode` | episode-code filter (e.g. `S01E01`) |

List response shape — `info` + `results` (identical structure to `/character`):

```json
{
  "info": {
    "count": 51,
    "pages": 3,
    "next": "https://rickandmortyapi.com/api/episode/?page=2",  // null on last page
    "prev": null
  },
  "results": [ { ...episode... } ]
}
```

Episode object (already mirrored by the existing `EpisodeDTO`):

```json
{
  "id": 1,
  "name": "Pilot",
  "air_date": "December 2, 2013",   // snake_case — EpisodeDTO already maps this
  "episode": "S01E01",              // episode code → season parsed from "S01"
  "characters": [ "https://rickandmortyapi.com/api/character/1", "..." ],
  "url": "https://rickandmortyapi.com/api/episode/1",
  "created": "2017-11-10T12:56:33.798Z"
}
```

### Data & Networking

- **Episode endpoint** — extend the existing `EpisodeEndpoint` with a paginated list case alongside the current `batch(ids:)`:
  - `case list(EpisodesListRequest)` → path `episode`, with `page` (and later `name` / `episode`) as query parameters, mirroring `CharacterEndpoint.list`. Add a private `EpisodesListRequestDTO: Encodable` in the endpoint file (like `CharactersRequestDTO`) so `nil` fields drop out of the query.
- **DTOs** — `EpisodeDTO` already exists and decodes the episode object. Add a paginated response DTO for episodes: `EpisodesResponseDTO { info: PageInfoDTO; results: [EpisodeDTO] }`. Reuse the existing `PageInfoDTO` (currently declared in `CharacterDTO.swift`) — do **not** duplicate it. If sharing it from the character file reads oddly, note it in the PR; do not move it without asking (surgical-changes rule).
- **Domain — new paginated repository**, kept separate from the batch `EpisodeRepository` (which serves a different query shape — by-ID vs. by-page). Per the Repository Convention (methods take a `…Request` struct, return a `…Response` struct) and the naming guardrail (avoid near-collisions):
  - `EpisodesRepository` protocol in `Domain/Repositories/` — `func episodes(matching request: EpisodesListRequest) async throws -> EpisodesListResponse`.
  - `EpisodesListRequest { var page: Int = 1 }` (name/episode filters added later by Search & Filter). `EpisodesListResponse { episodes: [Episode]; totalCount: Int; hasNextPage: Bool }` — same paging metadata as `CharactersResponse`.
  - **Naming note:** the existing batch protocol is `EpisodeRepository` (singular) with `EpisodesRequest`/`EpisodesResponse`; the new paginated one is `EpisodesRepository` (plural) with `EpisodesListRequest`/`EpisodesListResponse`. The one-letter singular/plural gap is uncomfortably close — flag it during implementation and, if it reads as error-prone, propose a clearer pair (e.g. rename the batch protocol to `EpisodeBatchRepository`) **before** writing the code, per the convention's guardrail. Do not silently rename.
  - Implementation `DefaultEpisodesRepository` in `Data/Repositories/` — builds `EpisodeEndpoint.list`, maps DTOs to domain, `hasNextPage = info.next != nil`, `totalCount = info.count`. Unlike `/character`, `/episode` is not expected to 404 for this feature (no filters are applied), so no 404→empty mapping is required; keep the repository minimal.
- **Use case — `FetchAllEpisodesUseCase`** (protocol + `Default` impl, one file) on top of `EpisodesRepository`. This is real orchestration (not a pass-through), so it earns a use case per the convention:
  - `func execute() async throws -> [Episode]` — fetches page 1, then keeps fetching subsequent pages while `hasNextPage`, accumulating results, and returns the flat list. Grouping into seasons is a Presentation concern, not the use case's job.
  - Fetch pages **sequentially** (only 3 pages, and it sidesteps the API's HTTP 429 rate limit that the Characters list already contends with). Do not parallelize — the dataset is tiny and sequential keeps it simple and rate-limit-friendly.
- **DI (`AppContainer`)** — add `episodesRepository: EpisodesRepository`, wire `DefaultEpisodesRepository` into `.live` and a new `PreviewEpisodesRepository` into `.preview`, and add `makeEpisodesListViewModel()` that builds the view model over `DefaultFetchAllEpisodesUseCase`.

### Presentation

- `Presentation/Episodes/List/` — new folder holding `EpisodesListView`, `EpisodesListViewModel`, and the row/section subviews (extract views past ~100 lines per coding standards).
- **`EpisodesListViewModel`** (`@Observable @MainActor`), depends on the `FetchAllEpisodesUseCase` protocol only (mockable seam for unit tests):
  - A `LoadState` (`idle` / `loading` / `loaded` / `empty` / `failed`) driving skeleton / content / empty / error, same shape as the Characters list.
  - `onAppear()` loads once (no-op if not `.idle`), `retry()` re-runs after a failure, `reload()` for pull-to-refresh.
  - Exposes `totalCount` for the badge and the **grouped** data for the view: an ordered array of season sections, each `{ season: Int, episodes: [Episode] }`, sorted by season, episodes sorted by episode number within a season. Derive season and episode number by parsing `episodeCode` (`S01E01` → season 1, episode 1); episodes whose code doesn't parse go into a trailing "Unknown" bucket rather than being dropped.
  - Guard against out-of-order completions with the same generation-token pattern the Characters list uses, so a superseded reload can't overwrite fresher results.
- **`EpisodesTab`** — replace the `PlaceholderView` with `EpisodesListView` built via `container.makeEpisodesListViewModel()`, keeping the `NavigationStack` bound to the coordinator's (still-empty) path. `TabBarView` currently constructs `EpisodesTab(coordinator:)` **without** a container — update that call site to pass `container`, mirroring `CharactersTab`.
- **States**: skeleton/shimmer section+rows while the first load runs, empty state if the list is somehow empty, error state with a Retry button on failure. Reuse the Characters list's skeleton/state styling for consistency.

### Behavior

- On appear, fetch all episode pages (3 requests), group by season, render sections.
- Pull-to-refresh re-fetches all pages and rebuilds the groups.
- Failure on **any** page aborts the load into the error state with Retry (all-or-nothing — a partial season list would be misleading). Retry restarts from page 1.
- No infinite scroll: the list is fully materialized after the initial load. The whole screen scrolls as one grouped list.

## Testing

Per the project's testing guidance — cover logic, not wiring:
- **`EpisodesListViewModel`**: state transitions (loading → loaded / empty / failed), retry path, and the season-grouping logic — correct section ordering, episode ordering within a section, and the "Unknown" bucket for an unparseable code. Race guard: a superseded reload doesn't overwrite fresher results. Mock the `FetchAllEpisodesUseCase` protocol.
- **`FetchAllEpisodesUseCase`**: multi-page accumulation (stops when `hasNextPage` is false; concatenates pages in order). Mock the `EpisodesRepository` protocol.
- **`DefaultEpisodesRepository`**: DTO → domain mapping and `hasNextPage`/`totalCount` derivation, driven by real wire JSON through a stubbed `APIClient` (same approach as the existing repository tests).
- Skip the SwiftUI views, the empty coordinator, and the season/episode-number parser only if it's a trivial one-liner — but since the grouping depends on it, test the parser's behavior via the view model's grouped output.

## Out of Scope

- Episode Detail screen (tapping a row) — separate follow-up feature; rows stay non-tappable and `EpisodesCoordinator.Route` stays empty.
- Name / episode-code search and filtering — Search & Filter feature.
- Any change to the existing batch `EpisodeRepository` / `FetchEpisodesUseCase` used by Character Detail (beyond the possible rename flagged above, which is a decision to raise, not a silent change).
- Favorites / SwiftData.

## References

- @context/project-overview.md (Module Structure, Use Case Convention, Repository Convention, Coordinator Convention, API Architecture)
- @context/coding-standards.md
- @context/features/characters-list-spec.md (paginated list pattern, header, states, race-guard)
- @context/features/character-detail-spec.md (existing Episode entity + batch Data-layer stack)
- @context/screenshots/characters-ui-light.png / characters-ui-dark.png (visual language reference)
- API docs: https://rickandmortyapi.com/documentation#episode
