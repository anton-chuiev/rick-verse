# Character Detail Spec

## Overview

Second vertical slice through all Clean Architecture layers, and the first screen that composes two API resources: a single character (`GET /character/{id}`) plus its episodes via batch fetch (`GET /episode/{id},{id},…`). Replaces `CharacterDetailPlaceholderView` behind the existing `CharactersCoordinator.Route.characterDetail(id:)` route with a real Detail screen: a hero image with the character's name and status overlaid, an About card with metadata, and an Episodes section. Introduces the `Episode` domain entity and its Data-layer stack, laying the foundation for the future Episodes feature. Follow the Module Structure, Use Case Convention, Repository Convention, and Coordinator Convention sections of the project overview.

There are no dedicated screenshots for this screen — reuse the visual language of the Characters List screenshots (cards on a light-gray/dark background, green accent, status dot colors, rounded corners).

## Requirements

### UI (hero layout)

Chosen layout (from the options discussed): edge-to-edge hero image with a gradient scrim and overlaid title.

```
┌───────────────────────────┐
│ ‹                       ♡ │   ← back + static heart, overlaid on image
│                           │
│      [ character image    │
│        full width,        │
│        edge-to-edge,      │
│        square ]           │
│ ▒▒▒▒▒ gradient scrim ▒▒▒▒ │
│ Rick Sanchez              │
│ ● Alive · Human           │
├───────────────────────────┤
│ ABOUT                     │
│ ┌───────────────────────┐ │
│ │ Gender      Male      │ │
│ │ Type        —         │ │
│ │ Origin      Earth C-137│ │
│ │ Last known  Citadel   │ │
│ │ First seen  Pilot     │ │
│ └───────────────────────┘ │
│ EPISODES · 51             │
│ ┌───────────────────────┐ │
│ │ S01E01  Pilot         │ │
│ │         Dec 2, 2013   │ │
│ ├───────────────────────┤ │
│ │ S01E02  Lawnmower Dog │ │
└───────────────────────────┘
```

- **Hero image**: the 300×300 avatar (Kingfisher) rendered full-width and square, extending under the navigation bar (ignore the top safe area). Reuse the list's placeholder + retry-on-throttle loading behavior. A bottom gradient scrim ensures overlay text is readable on any artwork in both light and dark mode.
- **Overlay on the scrim**: character name (large, bold) and a status line — status dot + status text (green Alive / red Dead / gray Unknown) · species, matching the list's styling.
- **Navigation bar**: back chevron (system) and a trailing outline heart, both legible over the image. The heart is **static and non-interactive** in this phase, consistent with the list — the real favorites toggle arrives with the Favorites feature.
- **About card** — labeled rows in a single card:
  - Gender (as returned by the API, e.g. "Male")
  - Type — show "—" when the API returns an empty string
  - Origin — `origin.name`
  - Last known location — `location.name`
  - First seen in — name of the character's **first episode**; fills in once episodes load (see Behavior)
- **Episodes section**: header "EPISODES · N" where N = number of episode IDs on the character. Each row: episode code badge (e.g. "S01E01"), episode name, air date. Rows are **not tappable** in this phase — Episode Detail is a separate feature.
- The whole screen scrolls as one unit; light and dark mode supported.

### API Reference (Rick and Morty API)

Base URL: `https://rickandmortyapi.com/api`

| Endpoint | Description |
|----------|-------------|
| `GET /character/{id}` | Single character by ID — returns the character object directly (same shape as the list spec's character object) |
| `GET /episode/{id},{id},…` | Multiple episodes by comma-separated IDs — returns a JSON **array** of episode objects |

- Note: an unknown character ID returns **404** `{ "error": "Character not found" }`. Unlike the list (where 404 means "no results"), here it is a real error → error state.
- Note: the batch episode endpoint returns an **array** for two or more IDs, but a **single object** (not a one-element array) when exactly one ID is requested — the decoder must handle both.

Episode object:

```json
{
  "id": 1,
  "name": "Pilot",
  "air_date": "December 2, 2013",      // snake_case — needs a CodingKey / key strategy
  "episode": "S01E01",                  // episode code
  "characters": [ "https://rickandmortyapi.com/api/character/1", "..." ],
  "url": "https://rickandmortyapi.com/api/episode/1",
  "created": "2017-11-10T12:56:33.798Z"
}
```

### Data & Networking

- **Character endpoint**: add `case detail(id: Int)` to `CharacterEndpoint` (path `character/{id}`, no query parameters).
- **Episode endpoint**: new `EpisodeEndpoint` in `Data/Network/` with `case batch(ids: [Int])` → path `episode/{comma-joined ids}`. All of a character's episodes fit in one request (max ~51 IDs — no chunking needed).
- **DTOs**: `EpisodeDTO` mirroring the JSON above. Mapping DTO → domain `Episode`: `air_date` → `airDate`, `episode` → `episodeCode`, `characters` URLs → `characterIDs` (parse trailing ID, same approach as the character mapper); `url`, `created` decoded but not carried into the domain.
- **Domain — extend `RMCharacter`** with the detail fields rather than adding a parallel detail entity: `gender: String`, `type: String`, `originName: String`. `CharacterDTO` already decodes them, so this is a mapper + entity change (the list simply doesn't display them). `created` stays DTO-only — "First seen in" is derived from the first episode, not from `created`.
- **Domain — `Episode`** entity per the project overview draft: `id`, `name`, `airDate`, `episodeCode`, `characterIDs`.
- **Repositories** — per the Repository Convention in the project overview (methods take a `…Request` struct and return a `…Response` struct, never bare scalars):
  - **Rename** the existing `CharacterRepository` → `CharactersRepository` (it serves the plural list): protocol, `DefaultCharacterRepository` → `DefaultCharactersRepository`, `PreviewCharacterRepository` → `PreviewCharactersRepository`, and their file names. No behavior change.
  - New `CharacterDetailRepository` protocol in `Domain/Repositories/` — `func character(matching request: CharacterDetailRequest) async throws -> CharacterDetailResponse`, where `CharacterDetailRequest` wraps the character `id` and `CharacterDetailResponse` wraps the fetched `RMCharacter`. Implementation `DefaultCharacterDetailRepository` in `Data/Repositories/`. (Named `CharacterDetail…`, not `Character…`, to avoid a one-letter difference from `CharactersRepository`.)
  - New `EpisodeRepository` protocol in `Domain/Repositories/` — `func episodes(matching request: EpisodesRequest) async throws -> EpisodesResponse`, where `EpisodesRequest` wraps the episode `ids` and `EpisodesResponse` wraps the `[Episode]` — with `DefaultEpisodeRepository` in `Data/Repositories/`. The repository hides the single-vs-array decoding quirk and returns an empty response for an empty `ids` array without hitting the network.
- **Use cases**:
  - `FetchEpisodesUseCase` (protocol + `Default` impl, one file) on top of `EpisodeRepository` — this is the batch-fetch orchestration the project overview cites as the canonical use-case example.
  - Fetching the character itself is a trivial pass-through — per the Use Case Convention, the view model may depend on `CharacterDetailRepository` directly; do not add a pass-through use case.
  - **Remove `FetchCharactersUseCase`**: it predates the Use Case Convention's guardrail and is a pure pass-through (`execute` just forwards to the repository). `CharactersListViewModel` switches to depending on the `CharactersRepository` protocol directly; update `AppContainer` and previews accordingly. Testability is unchanged — the repository protocol is the mockable seam.
- **Presentation**: `CharacterDetailView` + `CharacterDetailViewModel` in `Presentation/Characters/Detail/`, built via `AppContainer` like the list. Remove `CharacterDetailPlaceholderView` and wire the real view into `CharactersTab`'s `navigationDestination`.

### Behavior

- On appear, fetch the character by ID. While loading: skeleton/shimmer for the hero and About card.
- **Progressive loading**: render the hero + About as soon as the character arrives, then load episodes independently — shimmer rows in the Episodes section while the batch request runs. The "First seen in" row shows a shimmer/placeholder until episodes arrive.
- **Character load failure** (including 404): full-screen error state with a Retry button.
- **Episodes load failure**: inline error inside the Episodes section with its own Retry that re-requests only the episodes — the hero and About stay on screen.
- Defensive: if the character has no episode IDs, show an empty-section message instead of firing an empty batch request.
- The screen always fetches fresh by ID (the route carries only `id`, which also keeps deep links working) — it does not reuse the `RMCharacter` instance from the list.

## Out of Scope

- Favorites toggle / SwiftData (heart is display-only) — Favorites feature
- Tapping an episode row → Episode Detail — Episodes feature
- Episodes List screen / season grouping — Episodes feature
- Pull-to-refresh on the detail screen
- Seeding the screen with the already-loaded list character (always fetch by ID for now)

## References

- @context/project-overview.md (Module Structure, Use Case Convention, Repository Convention, Coordinator Convention, API Architecture)
- @context/coding-standards.md
- @context/features/characters-list-spec.md (character object shape, visual language)
- @context/screenshots/characters-ui-light.png / characters-ui-dark.png (visual language reference)
- API docs: https://rickandmortyapi.com/documentation#get-a-single-character
- API docs: https://rickandmortyapi.com/documentation#get-multiple-episodes
