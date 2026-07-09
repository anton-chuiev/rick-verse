# Characters List Spec

## Overview

First real content screen and the first full vertical slice through all Clean Architecture layers: Presentation (view + view model) → Domain (entity, use case, repository protocol) → Data (APIClient, DTOs, repository implementation). The Characters tab replaces its placeholder with a paginated, searchable list of characters fetched from the Rick and Morty API. Use the screenshots referenced below for how it should look. Follow the Module Structure, Use Case Convention, and Coordinator Convention sections of the project overview.

## Requirements

### UI (per screenshots)

- Header: "RICKVERSE" eyebrow label, "Characters" large title, and a total-count badge (e.g. "826 total") driven by the API's `info.count`
- Search field ("Search characters") below the header
- Status filter chips: All / Alive / Dead / Unknown, single-select, "All" selected by default
- Scrollable list of character cards, each showing: rounded character image (Kingfisher), name, status dot + status text (green Alive / red Dead / gray Unknown) · species, location pin icon + location name, heart icon, chevron
- Heart icon is static in this phase: outline heart on every card, non-interactive — real favorites arrive with the Favorites feature
- Tapping a card pushes a Character Detail placeholder: add `characterDetail(id:)` to `CharactersCoordinator.Route`, destination is a simple placeholder view — the real Detail screen is a separate follow-up feature
- Light and dark mode per the screenshots

### API Reference (Rick and Morty API)

Base URL: `https://rickandmortyapi.com/api`

Endpoints (only the first one is used in this feature; the rest are listed for context):

| Endpoint | Description |
|----------|-------------|
| `GET /character` | All characters, paginated (20 per page), filterable via query params |
| `GET /character/{id}` | Single character by ID |
| `GET /character/{id},{id},…` | Multiple characters by comma-separated IDs (later: batch fetch) |

Query parameters for `GET /character` (this feature uses `page`, `name`, `status`):

| Param | Values |
|-------|--------|
| `page` | page number, starts at 1 |
| `name` | free-text name filter |
| `status` | `alive`, `dead`, `unknown` |
| `species` | free text (Search & Filter feature) |
| `gender` | `female`, `male`, `genderless`, `unknown` (Search & Filter feature) |

Example: `GET /character/?page=1&name=rick&status=alive`

List response shape — `info` + `results`:

```json
{
  "info": {
    "count": 826,          // total matching characters → the "826 total" badge
    "pages": 42,
    "next": "https://rickandmortyapi.com/api/character/?page=2",  // null on last page
    "prev": null
  },
  "results": [ { ...character... } ]
}
```

Character object:

```json
{
  "id": 1,
  "name": "Rick Sanchez",
  "status": "Alive",        // "Alive" | "Dead" | "unknown"
  "species": "Human",
  "type": "",
  "gender": "Male",         // "Female" | "Male" | "Genderless" | "unknown"
  "origin":   { "name": "Earth", "url": "https://rickandmortyapi.com/api/location/1" },
  "location": { "name": "Earth", "url": "https://rickandmortyapi.com/api/location/20" },
  "image": "https://rickandmortyapi.com/api/character/avatar/1.jpeg",  // 300x300px avatar
  "episode": [ "https://rickandmortyapi.com/api/episode/1", "..." ],
  "url": "https://rickandmortyapi.com/api/character/1",
  "created": "2017-11-04T18:48:46.250Z"
}
```

- Note: the API returns **404 when no results match** the filters — map this to an empty result, not an error
- Note: `status`/`gender` values are capitalized in responses (`"Alive"`) but lowercase as query params (`status=alive`)

### Data & Networking

- Generic `APIClient` (URLSession + async/await) in `Data/Network/`
- DTOs in `Data/Network/` mirroring the JSON above: `CharacterDTO` (with nested `LocationRefDTO` for `origin`/`location`), `PageInfoDTO`, and a paginated response DTO (`info` + `results`)
- Mapping DTO → domain `Character`: `status` string → `Status` enum (case-insensitive), `location.name` → `locationName`, `image` → `imageURL`, `episode` URLs → `episodeIDs` (parse trailing ID from each URL); `type`, `gender`, `origin`, `url`, `created` are decoded but not carried into the domain entity for this feature
- Domain: `Character` entity per the project overview draft, `CharacterRepository` protocol in `Domain/Repositories/`, implementation in `Data/Repositories/` — repository returns items plus paging metadata (total count, has-next)
- `FetchCharactersUseCase` (protocol + `Default` impl, one file) orchestrating page/search/filter parameters; the view model depends on the protocol only

### Behavior

- Infinite scroll: load the next page when the user nears the end of the list; small progress footer while a page is loading; stop when `info.next` is null
- Search by name: debounced (~300 ms), resets to page 1, combined with the active status chip
- Status chips: selecting a chip resets to page 1 and refetches with the `status` param; works combined with the current search text
- Pull-to-refresh: reloads page 1 with the current search + filter
- States: skeleton/shimmer while loading the first page, empty state when no results, error state with a Retry button on first-page failure (page N failure should not blow away already-loaded items)
- Remove `Data/MockData.swift` — superseded by the real API

## Out of Scope

- Favorites toggle / SwiftData (heart is display-only) — Favorites feature
- Real Character Detail screen — separate follow-up feature
- Species / gender filters — Search & Filter feature
- Batch episode fetch — Character Detail / Episodes features

## References

- @context/project-overview.md (Module Structure, Use Case Convention, Coordinator Convention, API Architecture)
- @context/coding-standards.md
- @context/screenshots/characters-ui-light.png
- @context/screenshots/characters-ui-dark.png
- @context/features/tab-bar-spec.md
- API docs: https://rickandmortyapi.com/documentation/#character
