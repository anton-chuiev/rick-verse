# Favorites Spec

## Overview

The Favorites tab's first real screen, and the feature that introduces the project's **entire SwiftData persistence layer** — no `Data/Persistence/` stack, `@Model`, or `ModelContainer` exists yet. Favorites are an **offline-capable local store**: the user marks characters as favorite from the Characters List and Character Detail screens, and the Favorites tab lists them and lets them un-favorite. Because the store keeps a **snapshot** (id, name, image URL, status) per the project overview's Data Model draft, the Favorites list renders fully offline — it never hits the network.

This is a cross-cutting feature rather than a single vertical slice: it adds persistence (Data), a repository protocol (Domain), a shared observable store (Presentation), and wires a favorite toggle into **three** existing/new surfaces:
- **Characters List** — the currently-static heart on each `CharacterCardView` becomes an interactive toggle (add / remove).
- **Character Detail** — the currently-static heart in the toolbar becomes an interactive toggle (add / remove).
- **Favorites List** (new) — lists favorited characters from the store; each row can **remove** only (swipe / button); tapping a row opens Character Detail.

Follows the Module Structure, Repository Convention, Use Case Convention, and Coordinator Convention sections of the project overview.

There are no dedicated screenshots for this screen — reuse the visual language of the Characters List (cards on a light-gray/dark background, green accent, rounded corners, "RICKVERSE" eyebrow + large-title header). Favorites rows reuse the character-card look but with a filled heart and a remove affordance.

## Design Decisions (resolved)

These were decided up front; the rest of the spec assumes them.

1. **Separate `@Model FavoriteCharacter` + mapping (not storing `RMCharacter` directly).** `RMCharacter` stays a pure domain `struct` (Clean Architecture — Domain must not depend on SwiftData, and `coding-standards.md` requires value types for the domain). `@Model` requires a class, so persistence gets its own model. It stores only the **snapshot** the overview specifies (id, name, imageURLString, status, dateAdded) — the fields the Favorites card needs offline — not `episodeIDs` / `gender` / `origin`, which Favorites never reads. Consequence: a `FavoriteCharacter` cannot be rebuilt into a full `RMCharacter` (missing fields); the Favorites list renders from the snapshot directly, and tapping a row opens Character Detail by **id**, which re-fetches the full character from the network.

2. **Favorite state reaches the UI via a repository protocol + a shared observable store.** A `FavoritesRepository` protocol (Domain, `Sendable`) over a SwiftData store is the mockable seam; a shared `@Observable FavoritesStore` (Presentation) holds the in-memory set of favorited ids and the snapshot list, so the three screens react to changes without each running its own `@Query`. This keeps the protocol-seam / mockable-view-model conventions used everywhere else in the project, rather than sprinkling `@Query` through views. See **Presentation** for exactly what the store owns.

3. **`ModelContainer` created at the app root, repository built into `AppContainer`.** The container is created once at `rick_verseApp` / `AppShellView` and its `ModelContext` feeds `DefaultFavoritesRepository` in `AppContainer.live`. On-disk persistence (real offline across launches), not in-memory. `.preview` gets an in-memory container so previews stay isolated.

4. **Tap opens Character Detail inside the Favorites tab's own `NavigationStack`** (push within one flow — not cross-tab). `FavoritesCoordinator` gets a `Route.characterDetail(id:)` and a `navigationDestination`, mirroring `CharactersTab`. `AppCoordinator` is **not** involved (this isn't cross-tab navigation, so the "cross-tab only through AppCoordinator" rule doesn't apply). The Character Detail `navigationDestination` wiring is deliberately duplicated from `CharactersTab` — an accepted small duplication, kept local to each flow rather than shared, consistent with the one-coordinator-per-flow convention.

## Requirements

### Persistence (SwiftData — new layer)

New `Data/Persistence/` folder (per the Module Structure — "SwiftData stack, `FavoriteCharacter`"):

- **`@Model final class FavoriteCharacter`** exactly as drafted in `project-overview.md`:
  - `@Attribute(.unique) var id: Int` — the Rick and Morty character id; uniqueness makes "favorite the same character twice" an upsert, not a duplicate.
  - `var name: String`
  - `var imageURLString: String` — stored as `String` (SwiftData persists `String` cleanly; the domain/UI side converts to `URL?`). `nil` image → empty string.
  - `var status: String` — the raw API status string (`"Alive"` / `"Dead"` / `"unknown"`); mapped to `RMCharacter.Status` when read, using the existing case-insensitive `Status(apiValue:)`.
  - `var dateAdded: Date` — set to `.now` on insert; drives newest-first ordering on the Favorites screen.
  - `init(id:name:imageURLString:status:)` per the draft (sets `dateAdded = .now`).
- **`ModelContainer` setup** — a small factory (e.g. `PersistenceController` or a `ModelContainer` static factory) that builds the container for the `FavoriteCharacter` schema. On-disk for `.live`; an `isStoredInMemoryOnly: true` `ModelConfiguration` variant for previews/tests. Load `swiftdata-pro` before writing this — get the current `ModelContainer` / `ModelContext` / actor-isolation idioms right (Swift 6 strict concurrency, `@MainActor`).

### Domain

- **No new entity.** Favorites reuse the existing `RMCharacter` for the toggle input. The Favorites *list* is exposed as a lightweight snapshot type (see below) so Presentation doesn't import SwiftData.
- **`FavoriteCharacterSnapshot`** — a plain domain `struct` in `Domain/Entities/` representing a stored favorite for display: `id: Int`, `name: String`, `imageURL: URL?`, `status: RMCharacter.Status`, `dateAdded: Date`. `Identifiable, Equatable`. This is what the Favorites screen renders and what the repository returns — the `@Model` never leaves the Data layer.
- **`FavoritesRepository`** protocol in `Domain/Repositories/`, `Sendable`, per the Repository Convention (methods take a `…Request` domain struct where they carry input; a query/void where they don't). Keep it narrow:
  - `func favorites() async throws -> [FavoriteCharacterSnapshot]` — all favorites, newest-first (`dateAdded` descending).
  - `func favoriteIDs() async throws -> Set<Int>` — just the ids, for the store's fast `isFavorite` lookups without loading full snapshots. (If the store always loads full snapshots anyway, derive the id set from `favorites()` and drop this — decide during implementation; don't add a method the store won't call.)
  - `func add(_ character: FavoriteCharacterSnapshot) async throws` — upsert by id (unique constraint). Takes a snapshot so the repository never imports `RMCharacter`→snapshot mapping concerns; the mapping `RMCharacter → FavoriteCharacterSnapshot` lives at the call site / store.
  - `func remove(id: Int) async throws` — delete by id; a no-op if absent.
  - Naming: `FavoritesRepository` (the persisted favorites collection). No near-collision with the network `CharactersRepository` — different resource, different backing store.
- **No use case.** Each operation is a single call to a single repository with no orchestration, mapping across sources, or business rule — exactly the pass-through the Use Case Convention's guardrail says to skip. The store depends on the **`FavoritesRepository` protocol** directly; that protocol is the mockable seam for tests. Introduce a use case only if a real rule appears later (e.g. a favorites cap).

### Data (repository implementation + mapping)

- **`DefaultFavoritesRepository`** in `Data/Repositories/`, backed by a SwiftData `ModelContext`. `@MainActor` (or actor-isolated per the `swiftdata-pro` guidance) so it satisfies the `Sendable` protocol under Swift 6 strict concurrency while owning a non-`Sendable` `ModelContext`. Implements:
  - `favorites()` — `FetchDescriptor<FavoriteCharacter>` sorted by `dateAdded` descending → map each `@Model` to `FavoriteCharacterSnapshot`.
  - `favoriteIDs()` — fetch (ideally projecting just ids) → `Set<Int>`.
  - `add(_:)` — insert a `FavoriteCharacter` from the snapshot; the `.unique` id makes a repeat an upsert. Save.
  - `remove(id:)` — fetch by `#Predicate { $0.id == id }`, delete if found, save.
- **Mapping** lives next to the model in `Data/Persistence/` (e.g. `FavoriteCharacter+Mapping.swift`), mirroring the `…DTO+Mapping` pattern:
  - `FavoriteCharacter → FavoriteCharacterSnapshot`: `imageURLString` → `URL?` (empty/invalid → `nil`); `status` string → `RMCharacter.Status(apiValue:)`.
  - `RMCharacter → FavoriteCharacterSnapshot`: `imageURL?.absoluteString ?? ""`; `status` back to its raw string (add a small `RMCharacter.Status → apiValue` mapping, or store a canonical `"Alive"/"Dead"/"unknown"` — reuse the existing `title`/status conventions rather than inventing new strings). This is the toggle's add path.

### Presentation — shared store

- **`FavoritesStore`** (`@Observable @MainActor`), in `Presentation/Favorites/` (or `Presentation/Common/` if it reads better as shared infrastructure — it's consumed by Characters *and* Favorites screens). Depends on the `FavoritesRepository` protocol only (mockable seam for unit tests). Owns:
  - `private(set) var favoriteIDs: Set<Int>` — the source of truth the hearts observe; `isFavorite(id:) -> Bool` reads it synchronously so cards/toolbar render instantly without async.
  - `private(set) var favorites: [FavoriteCharacterSnapshot]` — the newest-first list the Favorites screen renders.
  - `func load() async` — populates both from the repository. Called on Favorites screen appear (and once at app start / first toggle so the ids are warm for the Characters screens — decide the cheapest warm-up point during implementation; don't over-eagerly load on every appear).
  - `func toggle(_ character: RMCharacter) async` — if favorited, `remove(id:)`; else `add(snapshot)`. **Optimistically** update `favoriteIDs` **and** `favorites` *before* the await so the heart flips immediately, then reconcile from the repository; on error, revert both. Both properties must move together on every mutation — this is what makes changes on one screen appear on the others (see Behavior → cross-screen reactivity). On add, the new snapshot is inserted at the **front** of `favorites` (newest-first, `dateAdded = .now`); on remove, it's dropped from `favorites`. Keep this behavior explicit and unit-tested.
  - `func remove(id: Int) async` — used by the Favorites screen's remove affordance; updates both properties.
  - Injected via `@Environment` (a single shared instance for the whole app, so all three screens see the same state) — created in `AppContainer` / at the app root and passed into the environment. **Not** rebuilt per screen (that would desync the hearts).
- **Concurrency note:** the store and repository are `@MainActor`; SwiftData `ModelContext` is main-actor-bound here (single shared context for a small favorites store — no background context needed at this scale). Run `swift-concurrency-pro` after writing the store to catch strict-concurrency issues.

### Presentation — toggle wiring (existing screens)

- **`CharacterCardView`** — replace the static `Image(systemName: "heart")` with an interactive button: filled `heart.fill` (accent/red) when `store.isFavorite(id: character.id)`, outline `heart` otherwise. Tapping calls `store.toggle(character)`. The card is currently wrapped in a selection `Button` (row tap → detail) in `CharactersListView`; the heart must be a **separate tappable control** that does not trigger the row's push (use `.buttonStyle(.plain)` on an inner button and stop the row selection from swallowing it — verify the heart tap and the row tap don't conflict). Update the card's accessibility to announce favorite state and expose a "favorite"/"unfavorite" action.
  - The card reads the store from `@Environment`. `CharacterCardView`'s `#Preview` must supply a preview store.
- **`CharacterDetailView`** — replace the static toolbar `Image(systemName: "heart")` with a toggle button: `heart.fill` when favorited, `heart` otherwise, calling `store.toggle(character)` (only enabled once `viewModel.character` is loaded — the toolbar heart is hidden/disabled while `.loading`/`.failed`, since there's no character to favorite yet). Reads the store from `@Environment`. Update accessibility (no longer `accessibilityHidden`).
- Both toggles operate on the **full `RMCharacter`** already on screen, so the snapshot is built from in-memory data — no fetch needed to favorite.

### Presentation — Favorites screen (new)

- `Presentation/Favorites/List/` (new folder) holding `FavoritesListView`, and — only if it carries logic beyond the shared store — a thin `FavoritesListViewModel`. **Prefer no separate view model:** the shared `FavoritesStore` already owns the list, load, and remove; the screen is a view over the store. Add a view model only if the screen needs its own state (e.g. an edit mode) — otherwise the view reads `store.favorites` directly and calls `store.remove(id:)` / `store.load()`. Decide during implementation and note the choice; don't add an empty pass-through VM.
- **Header** matching the Characters List: "RICKVERSE" eyebrow, "Favorites" large title, and a count badge (e.g. "12 saved") from `store.favorites.count`.
- **List body:** newest-first character rows (reuse the `CharacterCardView` look, or a trimmed favorites row showing image + name + status — no location/episode data is stored, so **do not** show a location line for favorites). Each row:
  - **Remove** affordance: swipe-to-delete and/or a filled-heart tap that removes. Removing calls `store.remove(id:)`; the row animates out.
  - **Tap** the row (not the remove control) → push Character Detail for that id via the coordinator.
- **States:** loading (brief skeleton while `store.load()` runs — usually instant since it's local), and an **empty state** ("No favorites yet — tap the heart on a character to save it here.") when `store.favorites.isEmpty`. No network error state (local store); a persistence read failure can surface a simple error state, but that's an edge case — keep it minimal.
- **`FavoritesTab`** — replace the `PlaceholderView` with `FavoritesListView`, keeping the `NavigationStack` bound to `coordinator.path`, and add the Character Detail `navigationDestination` (duplicated from `CharactersTab`, per Design Decision 4). `TabBarView` currently constructs `FavoritesTab(coordinator:)` **without** a container — update that call site to pass `container`, mirroring `CharactersTab` / `LocationsTab`.
- **`FavoritesCoordinator`** — add `enum Route: Hashable { case characterDetail(id: Int) }` and a `showCharacterDetail(id:)` that appends to `path`. (Currently `Route` is empty.)

### DI (`AppContainer`)

- Hold `favoritesRepository: FavoritesRepository` and the shared `FavoritesStore` (or build the store where the environment is injected — pick one and keep it single-instance).
- `.live` wires `DefaultFavoritesRepository` over the on-disk `ModelContext`; `.preview` wires it (or a `PreviewFavoritesRepository`) over an in-memory container so previews are isolated and don't touch disk.
- The `ModelContainer` is created at the app root (`rick_verseApp` / `AppShellView`) and injected into the environment (`.modelContainer(...)`), and its `mainContext` (or a context derived from it) is handed to `DefaultFavoritesRepository`. Ensure the **same** container backs both the environment and the repository so `@Query`-based debugging and the repository agree — but production reads go through the repository/store, not `@Query`.
- Inject the shared `FavoritesStore` into the SwiftUI environment at the shell level so all tabs share it.

### Behavior

- Favoriting from Characters List or Character Detail immediately flips the heart (optimistic) and persists; re-tapping un-favorites. The state is consistent across all three screens (same shared store) — favoriting on the list shows as favorited when you open that character's detail, and appears on the Favorites tab.
- **Cross-screen reactivity (required):** because the three screens read one shared `@Observable FavoritesStore`, a toggle on **any** screen updates the others live, with no manual refresh or re-fetch. Concretely: toggling the heart on **Character Detail** must, without leaving that screen or reloading, (a) update the corresponding card's heart on the **Characters List** underneath, and (b) add/remove that character on the **Favorites** tab. This works because `toggle` mutates both `favoriteIDs` (observed by the list/detail hearts) and `favorites` (observed by the Favorites screen) — the store is never rebuilt per screen and no screen keeps its own copy of favorite state. A regression here means one of those properties wasn't updated, or a screen holds favorite state outside the store.
- The Favorites tab lists favorites newest-first, renders offline from the snapshot, supports remove (swipe / heart tap), and pushes Character Detail on row tap. Removing on the Favorites tab likewise un-fills the heart on the Characters List / Detail live.
- Favorites survive app relaunch (on-disk SwiftData).
- Un-favoriting the last item shows the empty state.

## Testing

Per the project's testing guidance — cover logic, not wiring:

- **`FavoritesStore`** (mock the `FavoritesRepository` protocol): `toggle` adds when absent and removes when present; **optimistic update** flips `favoriteIDs`/`favorites` before the repository call resolves and **reverts on repository error**; `isFavorite(id:)` reflects the current set; `load()` populates newest-first; `remove(id:)` updates both properties. **Cross-screen consistency:** every mutation keeps `favoriteIDs` and `favorites` in agreement — after `toggle`-add, the id is in `favoriteIDs` *and* the snapshot is at the front of `favorites`; after `toggle`-remove (from either entry point) both drop it. This is the seam the "update Detail → List/Favorites update live" behavior rests on, so assert both properties explicitly on each mutation. If `toggle` can be invoked twice in quick succession (double-tap), assert the final state is consistent (mirror the list view models' race-guard discipline — gate the mock so two calls overlap; don't sleep on the wall clock).
- **`DefaultFavoritesRepository`** — drive it against an **in-memory `ModelContainer`** (`isStoredInMemoryOnly: true`), the SwiftData analogue of the repositories' stubbed `APIClient`: `add` then `favorites()` returns the snapshot; adding the same id twice upserts (no duplicate, thanks to `.unique`); `remove(id:)` deletes and is a no-op for an absent id; ordering is `dateAdded` descending; mapping round-trips (`imageURLString`↔`URL?` incl. empty→`nil`, `status` string↔`RMCharacter.Status`). Load `swiftdata-pro` / `swift-testing-pro` for the current in-memory-container test idiom.
- **Mapping** `RMCharacter ↔ FavoriteCharacterSnapshot ↔ FavoriteCharacter`: status round-trips case-insensitively; `nil`/empty image handled.
- Skip the SwiftUI views, the coordinator route (trivial append), and the empty-if-unused `FavoritesListViewModel`. No use case exists to test (intentional — see Domain).

## Out of Scope

- **Settings "clear favorites cache"** — the overview lists a clear-all action under Settings; it's a separate feature. No `removeAll()` and no Settings wiring here.
- **Favoriting locations or episodes** — favorites are characters only (matches the overview: `FavoriteCharacter`, toggle from Character Detail).
- **iCloud / CloudKit sync** — local-only SwiftData.
- **Reordering / sections / search within favorites** — flat newest-first list.
- **Background `ModelContext` / batch import** — single shared main-actor context is sufficient at this scale.

## References

- @context/project-overview.md (Data Model draft for `FavoriteCharacter`, Module Structure, Repository Convention, Use Case Convention, Coordinator Convention — cross-tab rule, Favorites feature description)
- @context/coding-standards.md (value-type domain, `@Observable`, strict concurrency)
- @context/features/characters-list-spec.md (card look, header, states, the static heart this feature makes interactive)
- @context/features/character-detail-spec.md (toolbar heart this feature makes interactive; Detail is reused as the Favorites row-tap destination)
- @context/features/locations-list-spec.md (sibling list slice — header/state styling, container threading into a tab)
- SwiftData docs — via `swiftdata-pro` skill (ModelContainer/ModelContext, `@Model`, `#Predicate`, in-memory config, Swift 6 isolation)
