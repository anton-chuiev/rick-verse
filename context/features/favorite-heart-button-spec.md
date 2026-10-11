# Extract FavoriteHeartButton (refactor)

## Problem

The favorite heart was duplicated as a private `favoriteButton` in `CharacterCardView` and `CharacterDetailView`, each reading `FavoritesStore.isFavorite(id:)` inside its own `body`. `@Observable` tracks dependencies per `body`, so every toggle (which mutates `favoriteIDs`) re-evaluated the `body` of every rendered card and the whole Character Detail screen — although only one heart actually changes.

## Change

- New `Presentation/Favorites/FavoriteHeartButton.swift` — reads `FavoritesStore` from the environment in its own `body`; filled + `statusDead` when favorited, `offColor` otherwise; toggles on tap; carries the VoiceOver label.
- `CharacterCardView` and `CharacterDetailView` embed it inline and drop their `@Environment(FavoritesStore.self)` dependency.
- Per-site styling stays at the call site: card — `offColor: textSecondary` + `.buttonStyle(.plain)` (isolates the heart tap from the row's push); detail — `offColor: .white` + `.shadow(radius: 4)` (moved from the image to the button; verified visually in the toolbar).

## Result

A toggle invalidates only the heart's `body`. No behavior change.

## Verification

- Full test suite green locally and in CI.
- Simulator: toggle on a card → Detail shows filled; toggle on Detail → white outline with shadow, toolbar glass unaffected.
- No new tests — the view has no logic beyond the already-tested `FavoritesStore` (SwiftUI views are out of test scope).
